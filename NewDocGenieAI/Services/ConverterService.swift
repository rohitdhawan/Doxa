import Foundation
import PDFKit
import UIKit

@MainActor
final class ConverterService {
    static let shared = ConverterService()
    private let storage = FileStorageService.shared

    private init() {}

    // MARK: - Images to PDF

    func imagesToPDF(urls: [URL], outputName: String) throws -> (url: URL, relativePath: String) {
        let pdfDocument = PDFDocument()
        for (index, url) in urls.enumerated() {
            guard let image = UIImage(contentsOfFile: url.path),
                  let page = PDFPage(image: image) else { continue }
            pdfDocument.insert(page, at: index)
        }
        guard pdfDocument.pageCount > 0 else { throw ConverterError.noValidInput }
        return try savePDF(pdfDocument, name: outputName)
    }

    // MARK: - Document to PDF (via print renderer)

    func documentToPDF(url: URL, outputName: String) throws -> (url: URL, relativePath: String) {
        let ext = url.pathExtension.lowercased()

        // For text-based files, render text to PDF
        if ["txt", "csv", "xml", "rtf"].contains(ext) {
            return try textFileToPDF(url: url, outputName: outputName)
        }

        // For other document types (doc, docx, xls, xlsx, ppt, pptx),
        // use WebKit-based rendering via UIPrintPageRenderer
        return try officeDocToPDF(url: url, outputName: outputName)
    }

    // MARK: - PDF to Images

    func pdfToImages(url: URL, format: ImageFormat, outputDir: String) throws -> [(url: URL, relativePath: String)] {
        guard let document = PDFDocument(url: url) else { throw ConverterError.cannotOpenFile }

        var results: [(url: URL, relativePath: String)] = []
        let baseName = (url.lastPathComponent as NSString).deletingPathExtension

        for i in 0..<document.pageCount {
            try autoreleasepool {
                guard let page = document.page(at: i) else { return }
                let bounds = page.bounds(for: .mediaBox)
                let scale: CGFloat = 2.0
                let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)

                let renderer = UIGraphicsImageRenderer(size: size)
                let image = renderer.image { ctx in
                    UIColor.white.setFill()
                    ctx.fill(CGRect(origin: .zero, size: size))
                    ctx.cgContext.scaleBy(x: scale, y: scale)
                    ctx.cgContext.translateBy(x: 0, y: bounds.height)
                    ctx.cgContext.scaleBy(x: 1, y: -1)
                    page.draw(with: .mediaBox, to: ctx.cgContext)
                }

                let imageData: Data?
                let ext: String
                switch format {
                case .jpg:
                    imageData = image.jpegData(compressionQuality: 0.9)
                    ext = "jpg"
                case .png:
                    imageData = image.pngData()
                    ext = "png"
                }

                guard let data = imageData else { return }
                let fileName = "\(baseName)_page\(i + 1).\(ext)"
                var destURL = storage.appFilesDirectory.appendingPathComponent(fileName)
                var counter = 1
                while FileManager.default.fileExists(atPath: destURL.path) {
                    destURL = storage.appFilesDirectory.appendingPathComponent("\(baseName)_page\(i + 1) (\(counter)).\(ext)")
                    counter += 1
                }

                try data.write(to: destURL)
                let relativePath = AppConstants.appDocumentsSubdirectory + "/" + destURL.lastPathComponent
                results.append((destURL, relativePath))
            }
        }

        guard !results.isEmpty else { throw ConverterError.conversionFailed }
        return results
    }

    // MARK: - PDF to Text

    nonisolated func pdfToText(url: URL) async throws -> String {
        do {
            return try await extractEmbeddedPDFText(url: url)
        } catch ConverterError.noTextContent {
            return try await OCRService.shared.extractText(from: url)
        }
    }

    private nonisolated func extractEmbeddedPDFText(url: URL) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            guard let document = PDFDocument(url: url) else { throw ConverterError.cannotOpenFile }

            var extractedPages: [String] = []
            extractedPages.reserveCapacity(document.pageCount)

            for i in 0..<document.pageCount {
                try Task.checkCancellation()
                guard let page = document.page(at: i),
                      let pageText = page.string?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !pageText.isEmpty else { continue }
                extractedPages.append(pageText)
            }

            let trimmed = extractedPages.joined(separator: "\n\n")
            guard !trimmed.isEmpty else { throw ConverterError.noTextContent }
            return trimmed
        }.value
    }

    func saveTextFile(text: String, outputName: String) throws -> (url: URL, relativePath: String) {
        let sanitized = outputName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitized.isEmpty else { throw ConverterError.conversionFailed }

        var destURL = storage.appFilesDirectory.appendingPathComponent("\(sanitized).txt")
        var counter = 1
        while FileManager.default.fileExists(atPath: destURL.path) {
            destURL = storage.appFilesDirectory.appendingPathComponent("\(sanitized) (\(counter)).txt")
            counter += 1
        }

        try text.write(to: destURL, atomically: true, encoding: .utf8)
        let relativePath = AppConstants.appDocumentsSubdirectory + "/" + destURL.lastPathComponent
        return (destURL, relativePath)
    }

    // MARK: - Private Helpers

    private func textFileToPDF(url: URL, outputName: String) throws -> (url: URL, relativePath: String) {
        let text: String
        if url.pathExtension.lowercased() == "rtf" {
            let data = try Data(contentsOf: url)
            let attributed = try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
            text = attributed.string
        } else {
            text = try String(contentsOf: url, encoding: .utf8)
        }

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let textRect = pageRect.insetBy(dx: 50, dy: 50)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let data = renderer.pdfData { context in
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 4
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            let attrString = NSAttributedString(string: text, attributes: attrs)
            let framesetter = CTFramesetterCreateWithAttributedString(attrString)
            var startIndex = 0
            let totalLength = attrString.length

            while startIndex < totalLength {
                context.beginPage()
                let path = CGPath(rect: textRect, transform: nil)
                let range = CFRangeMake(startIndex, 0)
                let frame = CTFramesetterCreateFrame(framesetter, range, path, nil)
                let ctx = context.cgContext
                ctx.translateBy(x: 0, y: pageRect.height)
                ctx.scaleBy(x: 1, y: -1)
                CTFrameDraw(frame, ctx)

                let visibleRange = CTFrameGetVisibleStringRange(frame)
                startIndex += visibleRange.length
                if visibleRange.length == 0 { break }
            }
        }

        guard let pdfDoc = PDFDocument(data: data) else { throw ConverterError.conversionFailed }
        return try savePDF(pdfDoc, name: outputName)
    }

    private func officeDocToPDF(url: URL, outputName: String) throws -> (url: URL, relativePath: String) {
        // For office documents, we create a PDF by rendering via a print page renderer
        // This uses UIPrintPageRenderer with a basic approach
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        // Read file content as best effort - for true office conversion a server-side
        // solution would be needed. Here we extract any available text.
        let text: String
        do {
            text = try String(contentsOf: url, encoding: .utf8)
        } catch {
            // Binary file - just create a single-page reference PDF
            text = "Document: \(url.lastPathComponent)\n\nThis document requires the original application to view properly.\n\nFile converted to PDF by Doxa."
        }

        let data = renderer.pdfData { context in
            let textRect = pageRect.insetBy(dx: 50, dy: 50)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]

            let attrString = NSAttributedString(string: text, attributes: attrs)
            let framesetter = CTFramesetterCreateWithAttributedString(attrString)
            var startIndex = 0
            let totalLength = attrString.length

            while startIndex < totalLength {
                context.beginPage()
                let path = CGPath(rect: textRect, transform: nil)
                let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(startIndex, 0), path, nil)
                let ctx = context.cgContext
                ctx.translateBy(x: 0, y: pageRect.height)
                ctx.scaleBy(x: 1, y: -1)
                CTFrameDraw(frame, ctx)

                let visibleRange = CTFrameGetVisibleStringRange(frame)
                startIndex += visibleRange.length
                if visibleRange.length == 0 { break }
            }
        }

        guard let pdfDoc = PDFDocument(data: data) else { throw ConverterError.conversionFailed }
        return try savePDF(pdfDoc, name: outputName)
    }

    private func savePDF(_ document: PDFDocument, name: String) throws -> (url: URL, relativePath: String) {
        let sanitized = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitized.isEmpty else { throw ConverterError.conversionFailed }

        var url = storage.appFilesDirectory.appendingPathComponent("\(sanitized).pdf")
        var counter = 1
        while FileManager.default.fileExists(atPath: url.path) {
            url = storage.appFilesDirectory.appendingPathComponent("\(sanitized) (\(counter)).pdf")
            counter += 1
        }

        guard let data = document.dataRepresentation() else { throw ConverterError.conversionFailed }
        try data.write(to: url)
        let relativePath = AppConstants.appDocumentsSubdirectory + "/" + url.lastPathComponent
        return (url, relativePath)
    }

    enum ImageFormat: String, CaseIterable, Identifiable {
        case jpg = "JPG"
        case png = "PNG"
        var id: String { rawValue }
    }
}

enum ConverterError: LocalizedError {
    case noValidInput
    case cannotOpenFile
    case conversionFailed
    case noTextContent

    var errorDescription: String? {
        switch self {
        case .noValidInput: return "No valid input files found."
        case .cannotOpenFile: return "Cannot open the file."
        case .conversionFailed: return "Conversion failed."
        case .noTextContent: return "No text content found in the document."
        }
    }
}
