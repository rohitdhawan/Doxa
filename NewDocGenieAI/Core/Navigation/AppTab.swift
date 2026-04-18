import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case chat
    case tools
    case files
    case transfer
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chat: return "Home"
        case .tools: return "Tools"
        case .files: return "Files"
        case .transfer: return "Transfer"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .chat: return "house.fill"
        case .tools: return "wrench.and.screwdriver"
        case .files: return "doc.on.doc"
        case .transfer: return "arrow.left.arrow.right"
        case .settings: return "gearshape"
        }
    }
}
