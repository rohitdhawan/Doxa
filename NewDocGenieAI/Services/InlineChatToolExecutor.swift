import Foundation
import SwiftData
import UIKit

@MainActor
final class InlineChatToolExecutor {
    static let shared = InlineChatToolExecutor()

    private let ocrService = OCRService.shared
    private let pdfToolsService = PDFToolsService.shared
    private let metadataService = FileMetadataService.shared

    private init() {}

    func execute(toolType: String, documentFile: DocumentFile, context: ModelContext) async -> InlineToolResult {
        do {
            switch toolType {
            case "ocr":
                return try await executeOCR(documentFile: documentFile)
            case "summarize":
                return try await executeSummarize(documentFile: documentFile)
            case "compress":
                return try await executeCompress(documentFile: documentFile, context: context)
            case "watermark":
                return try await executeWatermark(documentFile: documentFile, context: context)
            default:
                return InlineToolResult(
                    toolType: toolType,
                    success: false,
                    title: "Unknown Tool",
                    content: "Tool type '\(toolType)' is not supported."
                )
            }
        } catch {
            return InlineToolResult(
                toolType: toolType,
                success: false,
                title: "Error",
                content: error.localizedDescription
            )
        }
    }

    private func executeOCR(documentFile: DocumentFile) async throws -> InlineToolResult {
        let url = documentFile.fileURL!
        let text = try await ocrService.extractText(from: url)

        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return InlineToolResult(
                toolType: "ocr",
                success: true,
                title: "No Text Found",
                content: "No readable text was detected in this document."
            )
        }

        return InlineToolResult(
            toolType: "ocr",
            success: true,
            title: "Text Extracted",
            content: text.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private func executeSummarize(documentFile: DocumentFile) async throws -> InlineToolResult {
        let url = documentFile.fileURL!
        let text = try await ocrService.extractText(from: url)

        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return InlineToolResult(
                toolType: "summarize",
                success: false,
                title: "Cannot Summarize",
                content: "Could not extract text from the document to generate a summary."
            )
        }

        let summary = generateSimpleSummary(text)
        return InlineToolResult(
            toolType: "summarize",
            success: true,
            title: "Summary Generated",
            content: summary
        )
    }

    private func executeCompress(documentFile: DocumentFile, context: ModelContext) async throws -> InlineToolResult {
        let url = documentFile.fileURL!
        let outputName = "\(documentFile.name)_compressed"
        let result = try await pdfToolsService.compressPDF(from: url, level: .medium, outputName: outputName)

        let metadata = metadataService.extractMetadata(from: result.url)
        let newDoc = DocumentFile(
            name: outputName,
            fileExtension: "pdf",
            relativeFilePath: result.relativePath,
            fileSize: metadata.fileSize,
            pageCount: documentFile.pageCount
        )
        context.insert(newDoc)
        try? context.save()

        let originalSize = documentFile.fileSize
        let newSize = metadata.fileSize
        let reduction = originalSize > 0 ? ((originalSize - newSize) * 100 / originalSize) : 0

        return InlineToolResult(
            toolType: "compress",
            success: true,
            title: "PDF Compressed",
            content: "Reduced by \(reduction)% (\(formatFileSize(originalSize)) → \(formatFileSize(newSize)))",
            outputFileId: newDoc.id.uuidString,
            outputFileName: newDoc.fullFileName,
            originalSize: originalSize,
            compressedSize: newSize
        )
    }

    private func executeWatermark(documentFile: DocumentFile, context: ModelContext) async throws -> InlineToolResult {
        let url = documentFile.fileURL!
        let outputName = "\(documentFile.name)_watermarked"
        let result = try await pdfToolsService.addWatermark(from: url, text: "Doxa", outputName: outputName)

        let metadata = metadataService.extractMetadata(from: result.url)
        let newDoc = DocumentFile(
            name: outputName,
            fileExtension: "pdf",
            relativeFilePath: result.relativePath,
            fileSize: metadata.fileSize,
            pageCount: documentFile.pageCount
        )
        context.insert(newDoc)
        try? context.save()

        return InlineToolResult(
            toolType: "watermark",
            success: true,
            title: "Watermark Added",
            content: "Watermark \"Doxa\" applied to all pages.",
            outputFileId: newDoc.id.uuidString,
            outputFileName: newDoc.fullFileName
        )
    }

    private func generateSimpleSummary(_ text: String) -> String {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 20 }

        if sentences.isEmpty {
            return String(text.prefix(500))
        }

        let wordCount = text.split(separator: " ").count
        var lines = ["Document contains approximately \(wordCount) words.", ""]
        lines.append("Key points:")
        for (index, sentence) in sentences.prefix(5).enumerated() {
            lines.append("\(index + 1). \(String(sentence.prefix(150)))")
        }
        return lines.joined(separator: "\n")
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return "\(bytes / 1024) KB" }
        return String(format: "%.1f MB", Double(bytes) / (1024.0 * 1024.0))
    }
}
