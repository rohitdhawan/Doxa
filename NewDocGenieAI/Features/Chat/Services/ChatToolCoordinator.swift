import SwiftUI

@MainActor
@Observable
final class ChatToolCoordinator {
    var activeTool: ToolItem?
    var showScanner = false

    func openTool(_ tool: ToolItem) {
        HapticManager.medium()
        if tool == .scanner {
            showScanner = true
        } else {
            activeTool = tool
        }
    }

    func dismissTool() {
        activeTool = nil
    }

    func toolForId(_ id: String) -> ToolItem? {
        ToolItem.allCases.first { $0.rawValue == id || $0.id == id }
    }
}
