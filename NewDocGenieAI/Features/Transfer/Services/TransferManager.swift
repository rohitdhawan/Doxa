import Foundation
import MultipeerConnectivity
import SwiftUI

@MainActor
@Observable
final class TransferManager: NSObject {
    var discoveredPeers: [PeerDevice] = []
    var activeTransfers: [TransferItem] = []
    var transferHistory: [TransferItem] = []
    var isDiscovering = false
    var isBrowsing = false
    var isAdvertising = false
    var connectionStatus: ConnectionStatus = .disconnected
    var errorMessage: String?

    enum ConnectionStatus: String, Sendable {
        case disconnected = "Disconnected"
        case searching = "Searching..."
        case connecting = "Connecting..."
        case connected = "Connected"
    }

    private let serviceType = "docgenie-xfer"
    private let myPeerID: MCPeerID
    nonisolated(unsafe) private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    nonisolated(unsafe) private var peerIDMap: [String: MCPeerID] = [:]

    private let historyKey = "transfer_history"

    override init() {
        self.myPeerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()
        loadHistory()
    }

    // MARK: - Session Management

    func startSession() {
        let session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session
    }

    func startAdvertising() {
        startSession()
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        isAdvertising = true
        connectionStatus = .searching
    }

    func startBrowsing() {
        startSession()
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        isBrowsing = true
        isDiscovering = true
        connectionStatus = .searching
    }

    func stopAll() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        advertiser = nil
        browser = nil
        session = nil
        isAdvertising = false
        isBrowsing = false
        isDiscovering = false
        discoveredPeers = []
        peerIDMap = [:]
        connectionStatus = .disconnected
    }

    // MARK: - File Transfer

    func sendFile(url: URL, to peer: MCPeerID? = nil) {
        guard let session = session else { return }
        let targets = peer.map { [$0] } ?? session.connectedPeers

        guard !targets.isEmpty else {
            errorMessage = "No connected peers to send to"
            return
        }

        let fileName = url.lastPathComponent
        let fileExt = url.pathExtension
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0

        let transfer = TransferItem(
            fileName: fileName,
            fileSize: fileSize,
            fileType: fileExt,
            direction: .sent,
            method: .wifi,
            status: .inProgress,
            peerName: targets.first?.displayName ?? "Unknown"
        )

        activeTransfers.append(transfer)
        let transferID = transfer.id

        for target in targets {
            session.sendResource(at: url, withName: fileName, toPeer: target) { [weak self] error in
                Task { @MainActor [weak self] in
                    self?.handleSendCompletion(transferID: transferID, error: error)
                }
            }
        }
    }

    private func handleSendCompletion(transferID: UUID, error: Error?) {
        guard let idx = activeTransfers.firstIndex(where: { $0.id == transferID }) else { return }
        if let error = error {
            activeTransfers[idx].status = .failed
            errorMessage = error.localizedDescription
        } else {
            activeTransfers[idx].status = .completed
            activeTransfers[idx].progress = 1.0
        }
        let completed = activeTransfers[idx]
        transferHistory.insert(completed, at: 0)
        saveHistory()
        activeTransfers.remove(at: idx)
    }

    func shareViaActivitySheet(urls: [URL], from viewController: UIViewController) {
        let activityVC = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        viewController.present(activityVC, animated: true)
    }

    // MARK: - History

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([TransferItem].self, from: data) else { return }
        transferHistory = history
    }

    private func saveHistory() {
        let trimmed = Array(transferHistory.prefix(100))
        if let data = try? JSONEncoder().encode(trimmed) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    func clearHistory() {
        transferHistory.removeAll()
        UserDefaults.standard.removeObject(forKey: historyKey)
    }

    func removeHistoryItem(_ item: TransferItem) {
        transferHistory.removeAll { $0.id == item.id }
        saveHistory()
    }

    // MARK: - Helpers

    func connectToPeer(_ peer: MCPeerID) {
        guard let browser = browser, let session = session else { return }
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 30)
        connectionStatus = .connecting
    }

    func connectToPeer(_ peer: PeerDevice) {
        guard let mcPeerID = peerIDMap[peer.name] else { return }
        connectToPeer(mcPeerID)
    }

    // MARK: - Delegate Handlers (called from nonisolated delegates)

    fileprivate func handlePeerStateChange(peerName: String, state: MCSessionState) {
        switch state {
        case .connected:
            connectionStatus = .connected
            if let idx = discoveredPeers.firstIndex(where: { $0.name == peerName }) {
                discoveredPeers[idx].isConnected = true
            }
        case .notConnected:
            if session?.connectedPeers.isEmpty == true {
                connectionStatus = isDiscovering ? .searching : .disconnected
            }
            if let idx = discoveredPeers.firstIndex(where: { $0.name == peerName }) {
                discoveredPeers[idx].isConnected = false
            }
        case .connecting:
            connectionStatus = .connecting
        @unknown default:
            break
        }
    }

    fileprivate func handleStartReceivingResource(resourceName: String, peerName: String, progress: Progress) {
        let ext = (resourceName as NSString).pathExtension
        let transfer = TransferItem(
            fileName: resourceName,
            fileSize: Int64(progress.totalUnitCount),
            fileType: ext,
            direction: .received,
            method: .wifi,
            status: .inProgress,
            peerName: peerName
        )
        activeTransfers.append(transfer)
        let transferID = transfer.id

        progress.observe(\.fractionCompleted) { [weak self] prog, _ in
            Task { @MainActor [weak self] in
                if let idx = self?.activeTransfers.firstIndex(where: { $0.id == transferID }) {
                    self?.activeTransfers[idx].progress = prog.fractionCompleted
                }
            }
        }
    }

    fileprivate func handleFinishReceivingResource(resourceName: String, localURL: URL?, error: Error?) {
        guard let idx = activeTransfers.firstIndex(where: { $0.fileName == resourceName && $0.direction == .received }) else { return }

        if let error = error {
            activeTransfers[idx].status = .failed
            errorMessage = error.localizedDescription
        } else {
            activeTransfers[idx].status = .completed
            activeTransfers[idx].progress = 1.0

            if let localURL = localURL {
                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let dest = docs.appendingPathComponent("Received").appendingPathComponent(resourceName)
                try? FileManager.default.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
                try? FileManager.default.moveItem(at: localURL, to: dest)
            }
        }

        let completed = activeTransfers[idx]
        transferHistory.insert(completed, at: 0)
        saveHistory()
        activeTransfers.remove(at: idx)
    }

    fileprivate func handleFoundPeer(peerName: String) {
        guard !discoveredPeers.contains(where: { $0.name == peerName }) else { return }
        let deviceType: PeerDevice.DeviceType = {
            let name = peerName.lowercased()
            if name.contains("ipad") { return .ipad }
            if name.contains("mac") || name.contains("macbook") { return .mac }
            return .iphone
        }()
        let device = PeerDevice(
            id: UUID(),
            name: peerName,
            deviceType: deviceType,
            isConnected: false
        )
        discoveredPeers.append(device)
    }

    fileprivate func handleLostPeer(peerName: String) {
        discoveredPeers.removeAll { $0.name == peerName }
        peerIDMap.removeValue(forKey: peerName)
    }

    fileprivate func handleError(_ message: String) {
        errorMessage = message
    }

    fileprivate func makeLocalNetworkErrorMessage(action: String, error: Error) -> String {
        let nsError = error as NSError

        if nsError.domain == NetService.errorDomain {
            return "Unable to \(action) nearby devices right now. Please allow Local Network access for Doxa and try again."
        }

        return "Failed to \(action): \(error.localizedDescription)"
    }
}

// MARK: - MCSessionDelegate

extension TransferManager: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let name = peerID.displayName
        Task { @MainActor in
            self.handlePeerStateChange(peerName: name, state: state)
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {}

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}

    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        let name = peerID.displayName
        Task { @MainActor in
            self.handleStartReceivingResource(resourceName: resourceName, peerName: name, progress: progress)
        }
    }

    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        let url = localURL
        let err = error
        Task { @MainActor in
            self.handleFinishReceivingResource(resourceName: resourceName, localURL: url, error: err)
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension TransferManager: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Auto-accept and pass the session
        invitationHandler(true, self.session)
    }

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Task { @MainActor in
            self.isAdvertising = false
            self.connectionStatus = .disconnected
            self.handleError(self.makeLocalNetworkErrorMessage(action: "advertise", error: error))
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension TransferManager: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        let name = peerID.displayName
        // Store peerID mapping directly (nonisolated unsafe)
        self.peerIDMap[name] = peerID
        Task { @MainActor in
            self.handleFoundPeer(peerName: name)
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        let name = peerID.displayName
        Task { @MainActor in
            self.handleLostPeer(peerName: name)
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor in
            self.isBrowsing = false
            self.isDiscovering = false
            self.connectionStatus = .disconnected
            self.handleError(self.makeLocalNetworkErrorMessage(action: "browse for", error: error))
        }
    }
}
