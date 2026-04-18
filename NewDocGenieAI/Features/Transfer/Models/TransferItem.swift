import Foundation

enum TransferDirection: String, Codable {
    case sent
    case received
}

enum TransferStatus: String, Codable {
    case waiting
    case inProgress
    case completed
    case failed
    case cancelled
}

enum TransferMethod: String, Codable {
    case wifi
    case bluetooth
    case airdrop
    case qrCode

    var title: String {
        switch self {
        case .wifi: return "Wi-Fi"
        case .bluetooth: return "Bluetooth"
        case .airdrop: return "AirDrop"
        case .qrCode: return "QR Code"
        }
    }

    var systemImage: String {
        switch self {
        case .wifi: return "wifi"
        case .bluetooth: return "antenna.radiowaves.left.and.right"
        case .airdrop: return "airplayaudio"
        case .qrCode: return "qrcode"
        }
    }
}

struct TransferItem: Identifiable, Codable {
    let id: UUID
    let fileName: String
    let fileSize: Int64
    let fileType: String
    let direction: TransferDirection
    let method: TransferMethod
    var status: TransferStatus
    var progress: Double
    let peerName: String
    let timestamp: Date

    init(
        id: UUID = UUID(),
        fileName: String,
        fileSize: Int64,
        fileType: String,
        direction: TransferDirection,
        method: TransferMethod,
        status: TransferStatus = .waiting,
        progress: Double = 0,
        peerName: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.fileName = fileName
        self.fileSize = fileSize
        self.fileType = fileType
        self.direction = direction
        self.method = method
        self.status = status
        self.progress = progress
        self.peerName = peerName
        self.timestamp = timestamp
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var fileIcon: String {
        switch fileType.lowercased() {
        case "pdf": return "doc.fill"
        case "jpg", "jpeg", "png", "heic": return "photo.fill"
        case "doc", "docx": return "doc.text.fill"
        case "xls", "xlsx": return "tablecells.fill"
        case "mp4", "mov": return "video.fill"
        case "mp3", "wav": return "music.note"
        case "zip", "rar": return "archivebox.fill"
        default: return "doc.fill"
        }
    }
}

struct PeerDevice: Identifiable {
    let id: UUID
    let name: String
    let deviceType: DeviceType
    var isConnected: Bool

    enum DeviceType: String {
        case iphone = "iPhone"
        case ipad = "iPad"
        case mac = "Mac"
        case unknown = "Device"

        var systemImage: String {
            switch self {
            case .iphone: return "iphone"
            case .ipad: return "ipad"
            case .mac: return "laptopcomputer"
            case .unknown: return "desktopcomputer"
            }
        }
    }
}
