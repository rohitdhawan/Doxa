import Foundation

enum ChatActionType: String, Codable {
    case openTool
    case navigateTab
    case openFile
    case showResult
    case executeInline
    case copyText
    case shareFile
}

struct ChatAction: Identifiable, Codable {
    var id: UUID = UUID()
    let label: String
    let icon: String
    let actionType: ChatActionType
    var toolId: String?
    var tabId: String?
    var fileId: String?
    var payload: String?
}
