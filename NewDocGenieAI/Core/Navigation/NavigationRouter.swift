import SwiftUI

@Observable
final class NavigationRouter {
    var selectedTab: AppTab = .chat
    var filesPath = NavigationPath()
    var chatPath = NavigationPath()
    var toolsPath = NavigationPath()
    var toolToOpen: ToolItem?
    var incomingPDFURL: URL?
    var showIncomingPDF = false

    func navigateToFiles() {
        selectedTab = .files
    }

    func openToolFromAnywhere(_ tool: ToolItem) {
        selectedTab = .tools
        toolToOpen = tool
    }

    func openIncomingPDF(url: URL) {
        incomingPDFURL = url
        selectedTab = .chat
        showIncomingPDF = true
    }

    func resetCurrentTab() {
        switch selectedTab {
        case .files: filesPath = NavigationPath()
        case .chat: chatPath = NavigationPath()
        case .tools: toolsPath = NavigationPath()
        default: break
        }
    }
}
