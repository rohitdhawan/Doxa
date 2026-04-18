import SwiftData
import Foundation

@Model
final class DocumentFile {
    @Attribute(.unique) var id: UUID
    var name: String
    var fileExtension: String
    var relativeFilePath: String
    var fileSize: Int64
    var pageCount: Int?
    var importedAt: Date
    var originalCreatedAt: Date?
    var originalModifiedAt: Date?
    var lastOpenedAt: Date?
    var isFavorite: Bool

    @Transient var category: FileCategory {
        FileCategory.from(extension: fileExtension)
    }

    @Transient var viewerType: ViewerType {
        ViewerType.from(extension: fileExtension)
    }

    @Transient var fullFileName: String {
        "\(name).\(fileExtension)"
    }

    @Transient var fileURL: URL? {
        guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDir.appendingPathComponent(relativeFilePath)
    }

    init(
        name: String,
        fileExtension: String,
        relativeFilePath: String,
        fileSize: Int64,
        pageCount: Int? = nil,
        importedAt: Date = .now,
        originalCreatedAt: Date? = nil,
        originalModifiedAt: Date? = nil,
        isFavorite: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.fileExtension = fileExtension
        self.relativeFilePath = relativeFilePath
        self.fileSize = fileSize
        self.pageCount = pageCount
        self.importedAt = importedAt
        self.originalCreatedAt = originalCreatedAt
        self.originalModifiedAt = originalModifiedAt
        self.isFavorite = isFavorite
    }
}
