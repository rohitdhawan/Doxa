import SwiftData
import Foundation

@Model
final class ChatMessage {
    @Attribute(.unique) var id: UUID
    var content: String
    var role: String // "user", "assistant", "system"
    var timestamp: Date
    var conversationId: UUID
    var toolBadge: String? // e.g. "Scanner", "Merge PDF"
    var actionsJSON: String?
    var messageType: String = ""        // "", "documentCard", "processing", "toolResult"
    var documentFileId: String = ""     // UUID string of linked DocumentFile
    var resultDataJSON: String = ""     // JSON payload for tool results
    var inlineToolType: String = ""     // "ocr", "summarize", "compress", "watermark"

    @Transient var isUser: Bool {
        role == "user"
    }

    @Transient var isAssistant: Bool {
        role == "assistant"
    }

    @Transient private var _cachedActions: [ChatAction]?
    @Transient private var _cachedActionsJSON: String?

    @Transient var actions: [ChatAction] {
        if let cached = _cachedActions, _cachedActionsJSON == actionsJSON {
            return cached
        }
        guard let json = actionsJSON, let data = json.data(using: .utf8) else { return [] }
        let decoded = (try? JSONDecoder().decode([ChatAction].self, from: data)) ?? []
        _cachedActions = decoded
        _cachedActionsJSON = actionsJSON
        return decoded
    }

    init(
        content: String,
        role: String,
        conversationId: UUID,
        toolBadge: String? = nil,
        actions: [ChatAction] = [],
        messageType: String = "",
        documentFileId: String = "",
        resultDataJSON: String = "",
        inlineToolType: String = ""
    ) {
        self.id = UUID()
        self.content = content
        self.role = role
        self.timestamp = .now
        self.conversationId = conversationId
        self.toolBadge = toolBadge
        self.messageType = messageType
        self.documentFileId = documentFileId
        self.resultDataJSON = resultDataJSON
        self.inlineToolType = inlineToolType
        if !actions.isEmpty, let data = try? JSONEncoder().encode(actions) {
            self.actionsJSON = String(data: data, encoding: .utf8)
        }
    }
}
