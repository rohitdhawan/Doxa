import SwiftUI
import SwiftData

@Observable
final class FileActionsViewModel {
    private let storage = FileStorageService.shared

    func rename(_ file: DocumentFile, to newName: String, context: ModelContext) throws {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let newRelativePath = try storage.renameFile(at: file.relativeFilePath, to: trimmed)
        file.name = trimmed
        file.relativeFilePath = newRelativePath
        try context.save()
    }

    func delete(_ file: DocumentFile, context: ModelContext) throws {
        try storage.deleteFile(at: file.relativeFilePath)
        context.delete(file)
        try context.save()
    }

    func toggleFavorite(_ file: DocumentFile, context: ModelContext) throws {
        file.isFavorite.toggle()
        try context.save()
    }

    func share(_ file: DocumentFile) {
        guard let url = file.fileURL else { return }
        ShareService.shared.share(fileURL: url)
    }
}
