import Foundation
import PDFKit

struct FileMetadata {
    let fileSize: Int64
    let pageCount: Int?
    let createdAt: Date?
    let modifiedAt: Date?
}

final class FileMetadataService: Sendable {
    static let shared = FileMetadataService()

    func extractMetadata(from url: URL) -> FileMetadata {
        let fileManager = FileManager.default
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)

        let fileSize = (attributes?[.size] as? Int64) ?? 0
        let createdAt = attributes?[.creationDate] as? Date
        let modifiedAt = attributes?[.modificationDate] as? Date

        var pageCount: Int?
        if url.pathExtension.lowercased() == "pdf" {
            if let pdfDocument = PDFDocument(url: url) {
                pageCount = pdfDocument.pageCount
            }
        }

        return FileMetadata(
            fileSize: fileSize,
            pageCount: pageCount,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }
}
