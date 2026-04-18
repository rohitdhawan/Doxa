import Foundation
import Vision
import PDFKit
import UIKit

final class OCRService: Sendable {
    static let shared = OCRService()

    private init() {}

    func extractText(from url: URL) async throws -> String {
        let fileExtension = url.pathExtension.lowercased()

        if fileExtension == "pdf" {
            return try await extractTextFromPDF(url: url)
        } else {
            guard let image = UIImage(contentsOfFile: url.path) else {
                throw OCRError.cannotLoadImage
            }
            return try await extractTextFromImage(image)
        }
    }

    func extractTextFromImage(_ image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.cannotLoadImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")

                continuation.resume(returning: text)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func extractTextFromPDF(url: URL) async throws -> String {
        guard let document = PDFDocument(url: url) else {
            throw OCRError.cannotOpenPDF
        }

        var allText = ""

        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }

            // Try native text extraction first
            if let text = page.string, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                allText += text + "\n\n"
                continue
            }

            // Fall back to OCR for scanned pages
            let image: UIImage = autoreleasepool {
                let bounds = page.bounds(for: .mediaBox)
                let scale: CGFloat = 1.5
                let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)

                let renderer = UIGraphicsImageRenderer(size: size)
                return renderer.image { ctx in
                    UIColor.white.setFill()
                    ctx.fill(CGRect(origin: .zero, size: size))
                    ctx.cgContext.scaleBy(x: scale, y: scale)
                    ctx.cgContext.translateBy(x: 0, y: bounds.height)
                    ctx.cgContext.scaleBy(x: 1, y: -1)
                    page.draw(with: .mediaBox, to: ctx.cgContext)
                }
            }

            let pageText = try await extractTextFromImage(image)
            if !pageText.isEmpty {
                allText += pageText + "\n\n"
            }
        }

        guard !allText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OCRError.noTextFound
        }

        return allText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum OCRError: LocalizedError {
    case cannotLoadImage
    case cannotOpenPDF
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .cannotLoadImage: return "Cannot load the image for text recognition."
        case .cannotOpenPDF: return "Cannot open the PDF file."
        case .noTextFound: return "No text was found in the document."
        }
    }
}
