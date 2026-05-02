import SwiftUI
import SwiftData

@MainActor
@Observable
final class ConverterViewModel {
    var isProcessing = false
    var didComplete = false
    var errorMessage: String?
    var showError = false
    var resultFileName: String?
    var extractedText: String?

    private let service = ConverterService.shared

    // MARK: - Images to PDF

    func imagesToPDF(urls: [URL], outputName: String, context: ModelContext) {
        isProcessing = true
        defer { isProcessing = false }
        do {
            let result = try service.imagesToPDF(urls: urls, outputName: outputName)
            try saveResult(url: result.url, relativePath: result.relativePath, ext: "pdf", context: context)
            HapticManager.success()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.error()
        }
    }

    // MARK: - Document to PDF

    func documentToPDF(url: URL, outputName: String, context: ModelContext) {
        isProcessing = true
        defer { isProcessing = false }
        do {
            let result = try service.documentToPDF(url: url, outputName: outputName)
            try saveResult(url: result.url, relativePath: result.relativePath, ext: "pdf", context: context)
            HapticManager.success()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.error()
        }
    }

    // MARK: - PDF to Images

    func pdfToImages(url: URL, format: ConverterService.ImageFormat, context: ModelContext) {
        isProcessing = true
        defer { isProcessing = false }
        do {
            let results = try service.pdfToImages(url: url, format: format, outputDir: "")
            for result in results {
                let metadata = FileMetadataService.shared.extractMetadata(from: result.url)
                let ext = result.url.pathExtension.lowercased()
                let docFile = DocumentFile(
                    name: (result.url.lastPathComponent as NSString).deletingPathExtension,
                    fileExtension: ext,
                    relativeFilePath: result.relativePath,
                    fileSize: metadata.fileSize
                )
                context.insert(docFile)
            }
            try context.save()
            resultFileName = "\(results.count) images exported"
            didComplete = true
            HapticManager.success()

            // Notify chat about the batch export
            NotificationCenter.default.post(
                name: .toolDidProduceDocument,
                object: nil,
                userInfo: ["toolName": "PDF to Images", "batchCount": results.count]
            )
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.error()
        }
    }

    // MARK: - PDF to Text

    func pdfToText(url: URL) {
        isProcessing = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                extractedText = try await service.pdfToText(url: url)
                didComplete = true
                HapticManager.success()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                HapticManager.error()
            }
            isProcessing = false
        }
    }

    func saveExtractedText(outputName: String, context: ModelContext) {
        guard let text = extractedText else { return }
        isProcessing = true
        defer { isProcessing = false }
        do {
            let result = try service.saveTextFile(text: text, outputName: outputName)
            try saveResult(url: result.url, relativePath: result.relativePath, ext: "txt", context: context)
            HapticManager.success()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.error()
        }
    }

    // MARK: - Common

    private func saveResult(url: URL, relativePath: String, ext: String, context: ModelContext) throws {
        let metadata = FileMetadataService.shared.extractMetadata(from: url)
        let docFile = DocumentFile(
            name: (url.lastPathComponent as NSString).deletingPathExtension,
            fileExtension: ext,
            relativeFilePath: relativePath,
            fileSize: metadata.fileSize,
            pageCount: metadata.pageCount
        )
        context.insert(docFile)
        try context.save()
        resultFileName = docFile.fullFileName
        didComplete = true

        // Notify chat to show document card with auto-summary
        NotificationCenter.default.post(
            name: .toolDidProduceDocument,
            object: nil,
            userInfo: ["documentId": docFile.id.uuidString, "toolName": "Converter"]
        )
    }

    func reset() {
        isProcessing = false
        didComplete = false
        errorMessage = nil
        showError = false
        resultFileName = nil
        extractedText = nil
    }
}
