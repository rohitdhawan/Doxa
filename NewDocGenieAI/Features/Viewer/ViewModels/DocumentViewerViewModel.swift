import SwiftUI
import SwiftData

@Observable
final class DocumentViewerViewModel {
    var isLoading = true
    var errorMessage: String?

    func loadFile(_ file: DocumentFile, context: ModelContext) {
        guard let url = file.fileURL, FileManager.default.fileExists(atPath: url.path) else {
            errorMessage = "File not found. It may have been moved or deleted."
            isLoading = false
            return
        }

        file.lastOpenedAt = Date()
        try? context.save()
        isLoading = false
    }
}
