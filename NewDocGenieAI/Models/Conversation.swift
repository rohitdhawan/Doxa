import SwiftData
import Foundation

@Model
final class Conversation {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date

    init(title: String = "New Chat") {
        self.id = UUID()
        self.title = title
        self.createdAt = .now
        self.updatedAt = .now
    }
}
