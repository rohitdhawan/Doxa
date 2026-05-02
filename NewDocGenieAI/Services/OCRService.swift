import Foundation
import Vision
import PDFKit
import UIKit

final class OCRService: Sendable {
    static let shared = OCRService()

    private static let pdfOCRBaseScale: CGFloat = 1.5
    private static let pdfOCRMaxDimension: CGFloat = 2400
    private static let pdfOCRMaxPixelCount: CGFloat = 6_000_000

    private init() {}

    func extractText(from url: URL) async throws -> String {
        let fileExtension = url.pathExtension.lowercased()

        if fileExtension == "pdf" {
            return try await Task.detached(priority: .userInitiated) {
                try await self.extractTextFromPDF(url: url)
            }.value
        } else {
            return try await Task.detached(priority: .userInitiated) {
                try await self.extractTextFromImage(url: url)
            }.value
        }
    }

    func extractTextFromImage(_ image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.cannotLoadImage
        }

        return try await recognizeText { request in
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
        }
    }

    private func extractTextFromImage(url: URL) async throws -> String {
        try await recognizeText { request in
            let handler = VNImageRequestHandler(url: url, options: [:])
            try handler.perform([request])
        }
    }

    private func recognizeText(_ perform: @escaping (VNRecognizeTextRequest) throws -> Void) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let lock = NSLock()
            var didResume = false

            func resumeOnce(_ result: Result<String, Error>) {
                lock.lock()
                defer { lock.unlock() }

                guard !didResume else { return }
                didResume = true

                switch result {
                case .success(let text):
                    continuation.resume(returning: text)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    resumeOnce(.failure(error))
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")

                resumeOnce(.success(text))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            do {
                try perform(request)
            } catch {
                resumeOnce(.failure(error))
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

            guard let image = renderPageForOCR(page) else { continue }

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

    private func renderPageForOCR(_ page: PDFPage) -> UIImage? {
        autoreleasepool {
            let bounds = page.bounds(for: .mediaBox)
            guard bounds.width > 0, bounds.height > 0 else { return nil }

            let dimensionScale = min(
                Self.pdfOCRMaxDimension / bounds.width,
                Self.pdfOCRMaxDimension / bounds.height,
                Self.pdfOCRBaseScale
            )
            let pixelScale = sqrt(Self.pdfOCRMaxPixelCount / (bounds.width * bounds.height))
            let scale = max(0.1, min(dimensionScale, pixelScale))
            let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)

            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            format.opaque = true

            let renderer = UIGraphicsImageRenderer(size: size, format: format)
            return renderer.image { ctx in
                UIColor.white.setFill()
                ctx.fill(CGRect(origin: .zero, size: size))
                ctx.cgContext.scaleBy(x: scale, y: scale)
                ctx.cgContext.translateBy(x: -bounds.minX, y: bounds.maxY)
                ctx.cgContext.scaleBy(x: 1, y: -1)
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
        }
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
