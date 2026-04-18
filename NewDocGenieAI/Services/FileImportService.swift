import Foundation
import SwiftData

@MainActor
final class FileImportService {
    private let storage = FileStorageService.shared
    private let metadata = FileMetadataService.shared

    func importFiles(from urls: [URL], into modelContext: ModelContext) throws -> [DocumentFile] {
        var importedFiles: [DocumentFile] = []

        for url in urls {
            let result = try storage.importFile(from: url)
            let meta = metadata.extractMetadata(from: result.url)

            let fileName = (result.url.lastPathComponent as NSString).deletingPathExtension
            let ext = result.url.pathExtension.lowercased()

            let docFile = DocumentFile(
                name: fileName,
                fileExtension: ext,
                relativeFilePath: result.relativePath,
                fileSize: meta.fileSize,
                pageCount: meta.pageCount,
                originalCreatedAt: meta.createdAt,
                originalModifiedAt: meta.modifiedAt
            )

            modelContext.insert(docFile)
            importedFiles.append(docFile)
        }

        try modelContext.save()
        return importedFiles
    }
}
