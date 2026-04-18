import SwiftUI
import SwiftData
import PDFKit

@MainActor
@Observable
final class PDFToolsViewModel {
    var isProcessing = false
    var didComplete = false
    var errorMessage: String?
    var showError = false
    var resultFileName: String?

    private let service = PDFToolsService.shared

    func mergePDFs(urls: [URL], outputName: String, context: ModelContext) {
        performAsync(context: context) {
            try await self.service.mergePDFs(from: urls, outputName: outputName)
        }
    }

    func splitPDF(url: URL, startPage: Int, endPage: Int, outputName: String, context: ModelContext) {
        performAsync(context: context) {
            try await self.service.splitPDF(from: url, startPage: startPage, endPage: endPage, outputName: outputName)
        }
    }

    func compressPDF(url: URL, level: PDFToolsService.CompressionLevel, outputName: String, context: ModelContext) {
        performAsync(context: context) {
            try await self.service.compressPDF(from: url, level: level, outputName: outputName)
        }
    }

    func lockPDF(url: URL, password: String, outputName: String, context: ModelContext) {
        performAsync(context: context) {
            try await self.service.lockPDF(from: url, password: password, outputName: outputName)
        }
    }

    func unlockPDF(url: URL, password: String, outputName: String, context: ModelContext) {
        performAsync(context: context) {
            try await self.service.unlockPDF(from: url, password: password, outputName: outputName)
        }
    }

    func extractPages(url: URL, pageIndices: [Int], outputName: String, context: ModelContext) {
        performAsync(context: context) {
            try await self.service.extractPages(from: url, pageIndices: pageIndices, outputName: outputName)
        }
    }

    func rotatePDF(url: URL, degrees: Int, outputName: String, context: ModelContext) {
        performAsync(context: context) {
            try await self.service.rotatePDF(from: url, degrees: degrees, outputName: outputName)
        }
    }

    func reorderPDF(url: URL, newOrder: [Int], outputName: String, context: ModelContext) {
        performAsync(context: context) {
            try await self.service.reorderPDF(from: url, newOrder: newOrder, outputName: outputName)
        }
    }

    func addPageNumbers(url: URL, outputName: String, context: ModelContext) {
        performAsync(context: context) {
            try await self.service.addPageNumbers(from: url, outputName: outputName)
        }
    }

    func addWatermark(url: URL, text: String, outputName: String, context: ModelContext) {
        performAsync(context: context) {
            try await self.service.addWatermark(from: url, text: text, outputName: outputName)
        }
    }

    func signPDF(url: URL, signatureImage: UIImage, pageIndex: Int, position: CGPoint, signatureSize: CGSize, outputName: String, context: ModelContext) {
        performAsync(context: context) {
            try await self.service.signPDF(from: url, signatureImage: signatureImage, pageIndex: pageIndex, position: position, signatureSize: signatureSize, outputName: outputName)
        }
    }

    func cropPDF(url: URL, top: CGFloat, bottom: CGFloat, left: CGFloat, right: CGFloat, outputName: String, context: ModelContext) {
        performAsync(context: context) {
            try await self.service.cropPDF(from: url, top: top, bottom: bottom, left: left, right: right, outputName: outputName)
        }
    }

    func readMetadata(url: URL) -> PDFMetadata? {
        try? service.readMetadata(from: url)
    }

    func writeMetadata(url: URL, metadata: PDFMetadata, outputName: String, context: ModelContext) {
        performAsync(context: context) {
            try await self.service.writeMetadata(to: url, metadata: metadata, outputName: outputName)
        }
    }

    private func performAsync(context: ModelContext, operation: @escaping @Sendable () async throws -> (url: URL, relativePath: String)) {
        isProcessing = true
        Task { @MainActor in
            defer { isProcessing = false }
            do {
                let result = try await operation()
                try saveResult(url: result.url, relativePath: result.relativePath, context: context)
                HapticManager.success()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                HapticManager.error()
            }
        }
    }

    private func saveResult(url: URL, relativePath: String, context: ModelContext) throws {
        let metadata = FileMetadataService.shared.extractMetadata(from: url)
        let docFile = DocumentFile(
            name: (url.lastPathComponent as NSString).deletingPathExtension,
            fileExtension: "pdf",
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
            userInfo: ["documentId": docFile.id.uuidString, "toolName": "PDF Tool"]
        )
    }

    func reset() {
        isProcessing = false
        didComplete = false
        errorMessage = nil
        showError = false
        resultFileName = nil
    }
}
