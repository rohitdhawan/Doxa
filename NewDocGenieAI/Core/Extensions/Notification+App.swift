import Foundation

extension Notification.Name {
    /// Posted when a PDF tool or converter produces a new document file.
    /// userInfo keys: "documentId" (String), "toolName" (String), optional "batchCount" (Int)
    static let toolDidProduceDocument = Notification.Name("toolDidProduceDocument")
}
