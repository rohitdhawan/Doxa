import Foundation
import PDFKit
import UIKit

@MainActor
final class PDFToolsService {
    static let shared = PDFToolsService()
    private let storage = FileStorageService.shared

    private init() {}

    // MARK: - Merge

    func mergePDFs(from urls: [URL], outputName: String) async throws -> (url: URL, relativePath: String) {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                do {
                    let merged = PDFDocument()
                    var pageIndex = 0

                    for url in urls {
                        autoreleasepool {
                            guard let doc = PDFDocument(url: url) else { return }
                            for i in 0..<doc.pageCount {
                                guard let page = doc.page(at: i) else { continue }
                                merged.insert(page, at: pageIndex)
                                pageIndex += 1
                            }
                        }
                    }

                    guard pageIndex > 0 else { throw PDFToolsError.noValidPages }
                    let result = try self.savePDF(merged, name: outputName)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Split

    func splitPDF(from url: URL, startPage: Int, endPage: Int, outputName: String) async throws -> (url: URL, relativePath: String) {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                do {
                    guard let doc = PDFDocument(url: url) else { throw PDFToolsError.cannotOpenPDF }
                    let start = max(0, startPage - 1)
                    let end = min(doc.pageCount - 1, endPage - 1)
                    guard start <= end else { throw PDFToolsError.invalidPageRange }

                    let split = PDFDocument()
                    for i in start...end {
                        guard let page = doc.page(at: i) else { continue }
                        split.insert(page, at: split.pageCount)
                    }

                    let result = try self.savePDF(split, name: outputName)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Compress

    enum CompressionLevel: String, CaseIterable, Identifiable, Sendable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"

        var id: String { rawValue }

        var quality: CGFloat {
            switch self {
            case .low: return 0.8
            case .medium: return 0.5
            case .high: return 0.25
            }
        }

        var description: String {
            switch self {
            case .low: return "Best quality, slight reduction"
            case .medium: return "Balanced quality and size"
            case .high: return "Smallest size, lower quality"
            }
        }
    }

    func compressPDF(from url: URL, level: CompressionLevel, outputName: String) async throws -> (url: URL, relativePath: String) {
        let quality = level.quality
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                do {
                    guard let doc = PDFDocument(url: url) else { throw PDFToolsError.cannotOpenPDF }

                    let compressed = PDFDocument()
                    for i in 0..<doc.pageCount {
                        autoreleasepool {
                            guard let page = doc.page(at: i) else { return }
                            let bounds = page.bounds(for: .mediaBox)

                            let renderer = UIGraphicsImageRenderer(size: bounds.size)
                            let image = renderer.image { ctx in
                                UIColor.white.setFill()
                                ctx.fill(CGRect(origin: .zero, size: bounds.size))
                                ctx.cgContext.translateBy(x: 0, y: bounds.size.height)
                                ctx.cgContext.scaleBy(x: 1, y: -1)
                                page.draw(with: .mediaBox, to: ctx.cgContext)
                            }

                            if let jpegData = image.jpegData(compressionQuality: quality),
                               let compressedImage = UIImage(data: jpegData),
                               let newPage = PDFPage(image: compressedImage) {
                                compressed.insert(newPage, at: compressed.pageCount)
                            }
                        }
                    }

                    let result = try self.savePDF(compressed, name: outputName)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Lock (Password Protect)

    func lockPDF(from url: URL, password: String, outputName: String) async throws -> (url: URL, relativePath: String) {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                do {
                    guard let doc = PDFDocument(url: url) else { throw PDFToolsError.cannotOpenPDF }

                    let destinationURL = try self.uniqueDestination(for: outputName)
                    let success = doc.write(
                        to: destinationURL,
                        withOptions: [
                            .ownerPasswordOption: password,
                            .userPasswordOption: password
                        ]
                    )

                    guard success else { throw PDFToolsError.saveFailed }
                    let relativePath = AppConstants.appDocumentsSubdirectory + "/" + destinationURL.lastPathComponent
                    continuation.resume(returning: (destinationURL, relativePath))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Unlock

    func unlockPDF(from url: URL, password: String, outputName: String) async throws -> (url: URL, relativePath: String) {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                do {
                    guard let doc = PDFDocument(url: url) else { throw PDFToolsError.cannotOpenPDF }
                    guard doc.unlock(withPassword: password) else {
                        throw PDFToolsError.incorrectPassword
                    }

                    let unlocked = PDFDocument()
                    for i in 0..<doc.pageCount {
                        guard let page = doc.page(at: i) else { continue }
                        unlocked.insert(page, at: unlocked.pageCount)
                    }

                    let result = try self.savePDF(unlocked, name: outputName)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Extract Pages

    func extractPages(from url: URL, pageIndices: [Int], outputName: String) async throws -> (url: URL, relativePath: String) {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                do {
                    guard let doc = PDFDocument(url: url) else { throw PDFToolsError.cannotOpenPDF }

                    let extracted = PDFDocument()
                    for index in pageIndices {
                        let zeroIndex = index - 1
                        guard zeroIndex >= 0, zeroIndex < doc.pageCount,
                              let page = doc.page(at: zeroIndex) else { continue }
                        extracted.insert(page, at: extracted.pageCount)
                    }

                    guard extracted.pageCount > 0 else { throw PDFToolsError.noValidPages }
                    let result = try self.savePDF(extracted, name: outputName)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Rotate Pages

    func rotatePDF(from url: URL, degrees: Int, outputName: String) async throws -> (url: URL, relativePath: String) {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                do {
                    guard let doc = PDFDocument(url: url) else { throw PDFToolsError.cannotOpenPDF }

                    for i in 0..<doc.pageCount {
                        guard let page = doc.page(at: i) else { continue }
                        page.rotation = (page.rotation + degrees) % 360
                    }

                    let result = try self.savePDF(doc, name: outputName)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Reorder Pages

    func reorderPDF(from url: URL, newOrder: [Int], outputName: String) async throws -> (url: URL, relativePath: String) {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                do {
                    guard let doc = PDFDocument(url: url) else { throw PDFToolsError.cannotOpenPDF }

                    let reordered = PDFDocument()
                    for index in newOrder {
                        let zeroIndex = index - 1
                        guard zeroIndex >= 0, zeroIndex < doc.pageCount,
                              let page = doc.page(at: zeroIndex) else { continue }
                        reordered.insert(page, at: reordered.pageCount)
                    }

                    guard reordered.pageCount > 0 else { throw PDFToolsError.noValidPages }
                    let result = try self.savePDF(reordered, name: outputName)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Add Page Numbers

    func addPageNumbers(from url: URL, outputName: String) async throws -> (url: URL, relativePath: String) {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                do {
                    guard let doc = PDFDocument(url: url) else { throw PDFToolsError.cannotOpenPDF }

                    let numbered = PDFDocument()
                    for i in 0..<doc.pageCount {
                        autoreleasepool {
                            guard let page = doc.page(at: i) else { return }
                            let bounds = page.bounds(for: .mediaBox)

                            let renderer = UIGraphicsImageRenderer(size: bounds.size)
                            let image = renderer.image { ctx in
                                UIColor.white.setFill()
                                ctx.fill(CGRect(origin: .zero, size: bounds.size))
                                ctx.cgContext.translateBy(x: 0, y: bounds.size.height)
                                ctx.cgContext.scaleBy(x: 1, y: -1)
                                page.draw(with: .mediaBox, to: ctx.cgContext)

                                ctx.cgContext.scaleBy(x: 1, y: -1)
                                ctx.cgContext.translateBy(x: 0, y: -bounds.size.height)
                                let text = "\(i + 1)" as NSString
                                let attrs: [NSAttributedString.Key: Any] = [
                                    .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                                    .foregroundColor: UIColor.darkGray
                                ]
                                let size = text.size(withAttributes: attrs)
                                let point = CGPoint(
                                    x: (bounds.size.width - size.width) / 2,
                                    y: bounds.size.height - 30
                                )
                                text.draw(at: point, withAttributes: attrs)
                            }

                            if let newPage = PDFPage(image: image) {
                                numbered.insert(newPage, at: numbered.pageCount)
                            }
                        }
                    }

                    let result = try self.savePDF(numbered, name: outputName)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Add Watermark

    func addWatermark(from url: URL, text: String, outputName: String) async throws -> (url: URL, relativePath: String) {
        let watermarkText = text
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                do {
                    guard let doc = PDFDocument(url: url) else { throw PDFToolsError.cannotOpenPDF }

                    let watermarked = PDFDocument()
                    for i in 0..<doc.pageCount {
                        autoreleasepool {
                            guard let page = doc.page(at: i) else { return }
                            let bounds = page.bounds(for: .mediaBox)

                            let renderer = UIGraphicsImageRenderer(size: bounds.size)
                            let image = renderer.image { ctx in
                                UIColor.white.setFill()
                                ctx.fill(CGRect(origin: .zero, size: bounds.size))
                                ctx.cgContext.translateBy(x: 0, y: bounds.size.height)
                                ctx.cgContext.scaleBy(x: 1, y: -1)
                                page.draw(with: .mediaBox, to: ctx.cgContext)

                                ctx.cgContext.scaleBy(x: 1, y: -1)
                                ctx.cgContext.translateBy(x: 0, y: -bounds.size.height)

                                let nsText = watermarkText as NSString
                                let attrs: [NSAttributedString.Key: Any] = [
                                    .font: UIFont.systemFont(ofSize: 60, weight: .bold),
                                    .foregroundColor: UIColor.gray.withAlphaComponent(0.3)
                                ]
                                let textSize = nsText.size(withAttributes: attrs)

                                ctx.cgContext.saveGState()
                                ctx.cgContext.translateBy(x: bounds.size.width / 2, y: bounds.size.height / 2)
                                ctx.cgContext.rotate(by: -.pi / 4)
                                nsText.draw(
                                    at: CGPoint(x: -textSize.width / 2, y: -textSize.height / 2),
                                    withAttributes: attrs
                                )
                                ctx.cgContext.restoreGState()
                            }

                            if let newPage = PDFPage(image: image) {
                                watermarked.insert(newPage, at: watermarked.pageCount)
                            }
                        }
                    }

                    let result = try self.savePDF(watermarked, name: outputName)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Sign PDF

    func signPDF(from url: URL, signatureImage: UIImage, pageIndex: Int, position: CGPoint, signatureSize: CGSize, outputName: String) async throws -> (url: URL, relativePath: String) {
        let sigImg = signatureImage
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                do {
                    guard let doc = PDFDocument(url: url) else { throw PDFToolsError.cannotOpenPDF }
                    guard pageIndex >= 0, pageIndex < doc.pageCount else { throw PDFToolsError.invalidPageRange }

                    let signed = PDFDocument()
                    for i in 0..<doc.pageCount {
                        autoreleasepool {
                            guard let page = doc.page(at: i) else { return }
                            let bounds = page.bounds(for: .mediaBox)

                            let renderer = UIGraphicsImageRenderer(size: bounds.size)
                            let image = renderer.image { ctx in
                                UIColor.white.setFill()
                                ctx.fill(CGRect(origin: .zero, size: bounds.size))
                                ctx.cgContext.translateBy(x: 0, y: bounds.size.height)
                                ctx.cgContext.scaleBy(x: 1, y: -1)
                                page.draw(with: .mediaBox, to: ctx.cgContext)

                                if i == pageIndex {
                                    ctx.cgContext.scaleBy(x: 1, y: -1)
                                    ctx.cgContext.translateBy(x: 0, y: -bounds.size.height)
                                    let x = position.x * bounds.size.width - signatureSize.width / 2
                                    let y = position.y * bounds.size.height - signatureSize.height / 2
                                    let rect = CGRect(x: x, y: y, width: signatureSize.width, height: signatureSize.height)
                                    sigImg.draw(in: rect)
                                }
                            }

                            if let newPage = PDFPage(image: image) {
                                signed.insert(newPage, at: signed.pageCount)
                            }
                        }
                    }

                    let result = try self.savePDF(signed, name: outputName)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Crop PDF

    func cropPDF(from url: URL, top: CGFloat, bottom: CGFloat, left: CGFloat, right: CGFloat, outputName: String) async throws -> (url: URL, relativePath: String) {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                do {
                    guard let doc = PDFDocument(url: url), let data = doc.dataRepresentation() else {
                        throw PDFToolsError.cannotOpenPDF
                    }
                    guard let copy = PDFDocument(data: data) else { throw PDFToolsError.cannotOpenPDF }

                    for i in 0..<copy.pageCount {
                        guard let page = copy.page(at: i) else { continue }
                        let mediaBox = page.bounds(for: .mediaBox)
                        let cropRect = CGRect(
                            x: mediaBox.origin.x + left,
                            y: mediaBox.origin.y + bottom,
                            width: max(1, mediaBox.width - left - right),
                            height: max(1, mediaBox.height - top - bottom)
                        )
                        page.setBounds(cropRect, for: .cropBox)
                    }

                    let result = try self.savePDF(copy, name: outputName)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Read Metadata

    nonisolated func readMetadata(from url: URL) throws -> PDFMetadata {
        guard let doc = PDFDocument(url: url) else { throw PDFToolsError.cannotOpenPDF }
        let attrs = doc.documentAttributes ?? [:]
        return PDFMetadata(
            title: attrs[PDFDocumentAttribute.titleAttribute] as? String ?? "",
            author: attrs[PDFDocumentAttribute.authorAttribute] as? String ?? "",
            subject: attrs[PDFDocumentAttribute.subjectAttribute] as? String ?? "",
            keywords: (attrs[PDFDocumentAttribute.keywordsAttribute] as? [String])?.joined(separator: ", ") ?? ""
        )
    }

    // MARK: - Write Metadata

    func writeMetadata(to url: URL, metadata: PDFMetadata, outputName: String) async throws -> (url: URL, relativePath: String) {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                do {
                    guard let doc = PDFDocument(url: url) else { throw PDFToolsError.cannotOpenPDF }
                    var attrs = doc.documentAttributes ?? [:]
                    attrs[PDFDocumentAttribute.titleAttribute] = metadata.title
                    attrs[PDFDocumentAttribute.authorAttribute] = metadata.author
                    attrs[PDFDocumentAttribute.subjectAttribute] = metadata.subject
                    let keywords = metadata.keywords.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    attrs[PDFDocumentAttribute.keywordsAttribute] = keywords
                    doc.documentAttributes = attrs

                    let result = try self.savePDF(doc, name: outputName)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Helpers

    private nonisolated func savePDF(_ document: PDFDocument, name: String) throws -> (url: URL, relativePath: String) {
        let destinationURL = try uniqueDestination(for: name)

        guard let data = document.dataRepresentation() else {
            throw PDFToolsError.saveFailed
        }
        try data.write(to: destinationURL)

        let relativePath = AppConstants.appDocumentsSubdirectory + "/" + destinationURL.lastPathComponent
        return (destinationURL, relativePath)
    }

    private nonisolated func uniqueDestination(for name: String) throws -> URL {
        let sanitized = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitized.isEmpty else { throw PDFToolsError.saveFailed }

        let dir = FileStorageService.shared.appFilesDirectory
        var url = dir.appendingPathComponent("\(sanitized).pdf")
        var counter = 1
        while FileManager.default.fileExists(atPath: url.path) {
            url = dir.appendingPathComponent("\(sanitized) (\(counter)).pdf")
            counter += 1
        }
        return url
    }
}

enum PDFToolsError: LocalizedError {
    case cannotOpenPDF
    case noValidPages
    case invalidPageRange
    case incorrectPassword
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .cannotOpenPDF: return "Cannot open the PDF file."
        case .noValidPages: return "No valid pages found in the selected files."
        case .invalidPageRange: return "Invalid page range specified."
        case .incorrectPassword: return "The password is incorrect."
        case .saveFailed: return "Failed to save the PDF."
        }
    }
}

struct PDFMetadata: Sendable {
    var title: String
    var author: String
    var subject: String
    var keywords: String
}
