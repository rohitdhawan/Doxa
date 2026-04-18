import SwiftUI
import PhotosUI

struct TransferTabView: View {
    @State private var transferManager = TransferManager()
    @State private var selectedMode: TransferMode = .send
    @State private var showFilePicker = false
    @State private var showPhotoPicker = false
    @State private var showHistory = false
    @State private var showError = false
    @State private var showShareSheet = false
    @State private var shareURLs: [URL] = []
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showURLInput = false
    @State private var downloadURLString = ""
    @State private var isDownloading = false

    enum TransferMode: String, CaseIterable {
        case send = "Send"
        case receive = "Receive"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Connection Status Card
                    connectionStatusCard

                    // Mode Selector
                    modePicker

                    // Quick Actions
                    quickActionsSection

                    // Active Transfers
                    if !transferManager.activeTransfers.isEmpty {
                        activeTransfersSection
                    }

                    // Discovered Peers
                    if !transferManager.discoveredPeers.isEmpty {
                        discoveredPeersSection
                    }

                    // Recent Transfers
                    if !transferManager.transferHistory.isEmpty {
                        recentTransfersSection
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, 100)
            }
            .background(Color.appBGDark)
            .navigationTitle("Transfer")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(Color.appPrimary)
                    }
                }
            }
            .sheet(isPresented: $showHistory) {
                TransferHistoryView(transferManager: transferManager)
                    .presentationCornerRadius(24)
                    .presentationBackground(Color.appBackground)
            }
            .sheet(isPresented: $showFilePicker) {
                DocumentPickerView { urls in
                    for url in urls {
                        transferManager.sendFile(url: url)
                    }
                }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotos, matching: .images)
            .onChange(of: selectedPhotos) { _, newItems in
                handlePhotoSelection(items: newItems)
            }
            .sheet(isPresented: $showShareSheet) {
                if !shareURLs.isEmpty {
                    ActivityView(activityItems: shareURLs)
                }
            }
            .alert("Download from URL", isPresented: $showURLInput) {
                TextField("https://example.com/file.pdf", text: $downloadURLString)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button("Cancel", role: .cancel) {
                    downloadURLString = ""
                }
                Button("Download") {
                    downloadFromURL()
                }
            } message: {
                Text("Enter the URL of the file you want to download.")
            }
            .alert("Transfer Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(transferManager.errorMessage ?? "Unknown error")
            }
            .onChange(of: transferManager.errorMessage) { _, newValue in
                if newValue != nil {
                    showError = true
                }
            }
            .onDisappear {
                transferManager.stopAll()
            }
        }
    }

    // MARK: - Connection Status Card

    private var connectionStatusCard: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: statusIcon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(statusColor)
                        .symbolEffect(.pulse, options: .repeating, isActive: transferManager.isDiscovering)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(transferManager.connectionStatus.rawValue)
                        .font(.appH3)
                        .foregroundStyle(Color.appText)

                    Text(statusSubtitle)
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextMuted)
                }

                Spacer()

                Button {
                    if transferManager.isDiscovering || transferManager.isAdvertising {
                        transferManager.stopAll()
                    } else {
                        if selectedMode == .send {
                            transferManager.startBrowsing()
                        } else {
                            transferManager.startAdvertising()
                        }
                    }
                } label: {
                    Text(transferManager.isDiscovering || transferManager.isAdvertising ? "Stop" : "Start")
                        .font(.appCaption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            (transferManager.isDiscovering || transferManager.isAdvertising)
                            ? Color.appDanger
                            : Color.appPrimary
                        )
                        .clipShape(Capsule())
                }
            }

            if transferManager.connectionStatus == .connected {
                HStack(spacing: AppSpacing.xs) {
                    Circle()
                        .fill(Color.appSuccess)
                        .frame(width: 8, height: 8)

                    Text("\(transferManager.discoveredPeers.filter(\.isConnected).count) device(s) connected")
                        .font(.appCaption)
                        .foregroundStyle(Color.appSuccess)

                    Spacer()
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color.appBGCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                .stroke(Color.appBorder.opacity(0.3), lineWidth: 1)
        )
    }

    private var statusColor: Color {
        switch transferManager.connectionStatus {
        case .disconnected: return Color.appTextMuted
        case .searching: return Color.appWarning
        case .connecting: return Color.appAccent
        case .connected: return Color.appSuccess
        }
    }

    private var statusIcon: String {
        switch transferManager.connectionStatus {
        case .disconnected: return "wifi.slash"
        case .searching: return "antenna.radiowaves.left.and.right"
        case .connecting: return "arrow.triangle.2.circlepath"
        case .connected: return "checkmark.circle.fill"
        }
    }

    private var statusSubtitle: String {
        switch transferManager.connectionStatus {
        case .disconnected: return "Tap Start to discover nearby devices"
        case .searching: return "Looking for nearby devices..."
        case .connecting: return "Establishing connection..."
        case .connected: return "Ready to transfer files"
        }
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(TransferMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMode = mode
                        transferManager.stopAll()
                    }
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: mode == .send ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        Text(mode.rawValue)
                            .font(.appBody.weight(.medium))
                    }
                    .foregroundStyle(selectedMode == mode ? .white : Color.appTextMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm + 2)
                    .background(selectedMode == mode ? Color.appPrimary : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                }
            }
        }
        .padding(4)
        .background(Color.appBGElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Quick Actions")
                .font(.appH3)
                .foregroundStyle(Color.appText)

            if selectedMode == .send {
                sendQuickActions
            } else {
                receiveQuickActions
            }
        }
    }

    private var sendQuickActions: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                quickActionCard(
                    icon: "doc.fill",
                    title: "Send Files",
                    subtitle: "Select & send documents",
                    color: Color.appPrimary
                ) {
                    showFilePicker = true
                }

                quickActionCard(
                    icon: "photo.fill",
                    title: "Send Photos",
                    subtitle: "Share images & photos",
                    color: Color.appAccent
                ) {
                    showPhotoPicker = true
                }
            }

            HStack(spacing: AppSpacing.sm) {
                quickActionCard(
                    icon: "qrcode",
                    title: "QR Transfer",
                    subtitle: "Generate QR to share",
                    color: Color.appSuccess
                ) {
                    showFilePicker = true
                }

                quickActionCard(
                    icon: "square.and.arrow.up",
                    title: "Share via...",
                    subtitle: "AirDrop, Mail & more",
                    color: Color.appWarning
                ) {
                    showFilePicker = true
                }
            }
        }
    }

    private var receiveQuickActions: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                quickActionCard(
                    icon: "antenna.radiowaves.left.and.right",
                    title: "Wi-Fi Direct",
                    subtitle: "Receive via local network",
                    color: Color.appPrimary
                ) {
                    transferManager.startAdvertising()
                }

                quickActionCard(
                    icon: "qrcode.viewfinder",
                    title: "Scan QR",
                    subtitle: "Scan to receive files",
                    color: Color.appAccent
                ) {
                    // QR scanning requires camera - start advertising as fallback
                    transferManager.startAdvertising()
                }
            }

            HStack(spacing: AppSpacing.sm) {
                quickActionCard(
                    icon: "icloud.and.arrow.down",
                    title: "From Cloud",
                    subtitle: "Import from cloud storage",
                    color: Color.appSuccess
                ) {
                    showFilePicker = true
                }

                quickActionCard(
                    icon: "link",
                    title: "From URL",
                    subtitle: "Download from a link",
                    color: Color.appWarning
                ) {
                    showURLInput = true
                }
            }
        }
    }

    private func quickActionCard(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 42, height: 42)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.appBody.weight(.semibold))
                        .foregroundStyle(Color.appText)

                    Text(subtitle)
                        .font(.appMicro)
                        .foregroundStyle(Color.appTextMuted)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.sm + 4)
            .background(Color.appBGCard)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.md)
                    .stroke(Color.appBorder.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Active Transfers

    private var activeTransfersSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Active Transfers")
                    .font(.appH3)
                    .foregroundStyle(Color.appText)

                Spacer()

                Text("\(transferManager.activeTransfers.count)")
                    .font(.appCaption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.appPrimary)
                    .clipShape(Capsule())
            }

            ForEach(transferManager.activeTransfers) { item in
                TransferProgressCard(item: item)
            }
        }
    }

    // MARK: - Discovered Peers

    private var discoveredPeersSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Nearby Devices")
                .font(.appH3)
                .foregroundStyle(Color.appText)

            ForEach(transferManager.discoveredPeers) { peer in
                PeerDeviceRow(peer: peer) {
                    transferManager.connectToPeer(peer)
                }
            }
        }
    }

    // MARK: - Recent Transfers

    private var recentTransfersSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Recent Transfers")
                    .font(.appH3)
                    .foregroundStyle(Color.appText)

                Spacer()

                Button {
                    showHistory = true
                } label: {
                    Text("See All")
                        .font(.appCaption.weight(.medium))
                        .foregroundStyle(Color.appPrimary)
                }
            }

            ForEach(transferManager.transferHistory.prefix(3)) { item in
                TransferHistoryRow(item: item)
            }
        }
    }

    // MARK: - Photo Selection

    private func handlePhotoSelection(items: [PhotosPickerItem]) {
        Task {
            for item in items {
                guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString + ".jpg")
                try? data.write(to: tempURL)
                await MainActor.run {
                    transferManager.sendFile(url: tempURL)
                }
            }
            await MainActor.run {
                selectedPhotos = []
            }
        }
    }

    // MARK: - URL Download

    private func downloadFromURL() {
        guard let url = URL(string: downloadURLString.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme != nil else {
            transferManager.errorMessage = "Please enter a valid URL"
            return
        }

        isDownloading = true
        Task {
            do {
                let (tempURL, response) = try await URLSession.shared.download(from: url)
                let fileName: String
                if let httpResponse = response as? HTTPURLResponse,
                   let contentDisposition = httpResponse.value(forHTTPHeaderField: "Content-Disposition"),
                   let name = contentDisposition.components(separatedBy: "filename=").last?.trimmingCharacters(in: .init(charactersIn: "\"")) {
                    fileName = name
                } else {
                    fileName = url.lastPathComponent.isEmpty ? "download" : url.lastPathComponent
                }

                let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let receivedDir = docsDir.appendingPathComponent("Received", isDirectory: true)
                try? FileManager.default.createDirectory(at: receivedDir, withIntermediateDirectories: true)
                let destURL = receivedDir.appendingPathComponent(fileName)

                if FileManager.default.fileExists(atPath: destURL.path) {
                    try? FileManager.default.removeItem(at: destURL)
                }
                try FileManager.default.moveItem(at: tempURL, to: destURL)

                await MainActor.run {
                    isDownloading = false
                    downloadURLString = ""
                }
            } catch {
                await MainActor.run {
                    isDownloading = false
                    transferManager.errorMessage = "Download failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct TransferProgressCard: View {
    let item: TransferItem

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color.appPrimary.opacity(0.12))
                        .frame(width: 40, height: 40)

                    Image(systemName: item.direction == .sent ? "arrow.up" : "arrow.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.appPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.fileName)
                        .font(.appBody.weight(.medium))
                        .foregroundStyle(Color.appText)
                        .lineLimit(1)

                    Text("\(item.formattedSize) • \(item.peerName)")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextMuted)
                }

                Spacer()

                Text("\(Int(item.progress * 100))%")
                    .font(.appCaption.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
            }

            ProgressView(value: item.progress)
                .tint(Color.appPrimary)
        }
        .padding(AppSpacing.sm + 4)
        .background(Color.appBGCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                .stroke(Color.appBorder.opacity(0.2), lineWidth: 1)
        )
    }
}

struct PeerDeviceRow: View {
    let peer: PeerDevice
    let onConnect: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(peer.isConnected ? Color.appSuccess.opacity(0.12) : Color.appBGElevated)
                    .frame(width: 44, height: 44)

                Image(systemName: peer.deviceType.systemImage)
                    .font(.system(size: 20))
                    .foregroundStyle(peer.isConnected ? Color.appSuccess : Color.appTextMuted)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(peer.name)
                    .font(.appBody.weight(.medium))
                    .foregroundStyle(Color.appText)

                Text(peer.isConnected ? "Connected" : peer.deviceType.rawValue)
                    .font(.appCaption)
                    .foregroundStyle(peer.isConnected ? Color.appSuccess : Color.appTextMuted)
            }

            Spacer()

            if !peer.isConnected {
                Button("Connect", action: onConnect)
                    .font(.appCaption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppSpacing.sm + 4)
                    .padding(.vertical, AppSpacing.xs + 2)
                    .background(Color.appPrimary)
                    .clipShape(Capsule())
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.appSuccess)
            }
        }
        .padding(AppSpacing.sm + 4)
        .background(Color.appBGCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                .stroke(Color.appBorder.opacity(0.2), lineWidth: 1)
        )
    }
}

struct TransferHistoryRow: View {
    let item: TransferItem

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                    .fill(item.direction == .sent ? Color.appPrimary.opacity(0.1) : Color.appSuccess.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: item.fileIcon)
                    .font(.system(size: 17))
                    .foregroundStyle(item.direction == .sent ? Color.appPrimary : Color.appSuccess)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.fileName)
                    .font(.appBody.weight(.medium))
                    .foregroundStyle(Color.appText)
                    .lineLimit(1)

                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: item.direction == .sent ? "arrow.up.right" : "arrow.down.left")
                        .font(.system(size: 10, weight: .bold))

                    Text("\(item.direction == .sent ? "Sent to" : "From") \(item.peerName)")
                        .lineLimit(1)

                    Text("•")

                    Text(item.formattedSize)
                }
                .font(.appCaption)
                .foregroundStyle(Color.appTextMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                statusBadge

                Text(item.timestamp, style: .relative)
                    .font(.appMicro)
                    .foregroundStyle(Color.appTextDim)
            }
        }
        .padding(AppSpacing.sm + 4)
        .background(Color.appBGCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                .stroke(Color.appBorder.opacity(0.2), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch item.status {
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.appSuccess)
                .font(.system(size: 16))
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(Color.appDanger)
                .font(.system(size: 16))
        case .cancelled:
            Image(systemName: "minus.circle.fill")
                .foregroundStyle(Color.appTextMuted)
                .font(.system(size: 16))
        default:
            ProgressView()
                .controlSize(.small)
        }
    }
}

