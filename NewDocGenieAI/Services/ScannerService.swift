import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import PDFKit

@MainActor
final class ScannerService {
    static let shared = ScannerService()
    private let ciContext = CIContext()

    private init() {}

    // MARK: - Image Filtering

    func applyFilter(_ filter: ScanFilter, to image: UIImage) -> UIImage {
        guard filter != .color else { return image }
        guard let ciImage = CIImage(image: image) else { return image }

        let filtered: CIImage
        switch filter {
        case .color:
            return image
        case .grayscale:
            filtered = applyGrayscale(to: ciImage)
        case .blackAndWhite:
            filtered = applyBlackAndWhite(to: ciImage)
        case .sharpen:
            filtered = applySharpen(to: ciImage)
        }

        guard let cgImage = ciContext.createCGImage(filtered, from: filtered.extent) else {
            return image
        }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    func rotateImage(_ image: UIImage, by degrees: Int) -> UIImage {
        let radians = CGFloat(degrees) * .pi / 180
        let rotatedSize = CGRect(
            origin: .zero,
            size: image.size
        ).applying(CGAffineTransform(rotationAngle: radians)).integral.size

        UIGraphicsBeginImageContextWithOptions(rotatedSize, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return image }

        context.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        context.rotate(by: radians)
        image.draw(in: CGRect(
            x: -image.size.width / 2,
            y: -image.size.height / 2,
            width: image.size.width,
            height: image.size.height
        ))

        let rotated = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rotated ?? image
    }

    // MARK: - PDF Generation

    func generatePDF(from pages: [ScannedPage]) -> Data? {
        let pdfDocument = PDFDocument()
        for (index, page) in pages.enumerated() {
            guard let pdfPage = PDFPage(image: page.currentImage) else { continue }
            pdfDocument.insert(pdfPage, at: index)
        }
        return pdfDocument.dataRepresentation()
    }

    func saveScanAsPDF(
        pages: [ScannedPage],
        fileName: String
    ) throws -> (url: URL, relativePath: String) {
        guard let pdfData = generatePDF(from: pages) else {
            throw ScannerError.pdfGenerationFailed
        }

        let storage = FileStorageService.shared
        let sanitized = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = sanitized.isEmpty
            ? "Scan \(Date.now.formatted(.dateTime.month(.abbreviated).day().hour().minute()))"
            : sanitized

        var destinationURL = storage.appFilesDirectory.appendingPathComponent("\(name).pdf")
        var counter = 1
        while FileManager.default.fileExists(atPath: destinationURL.path) {
            destinationURL = storage.appFilesDirectory.appendingPathComponent("\(name) (\(counter)).pdf")
            counter += 1
        }

        try pdfData.write(to: destinationURL)
        let relativePath = AppConstants.appDocumentsSubdirectory + "/" + destinationURL.lastPathComponent
        return (destinationURL, relativePath)
    }

    // MARK: - Private Filters

    private func applyGrayscale(to ciImage: CIImage) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = ciImage
        filter.saturation = 0.0
        return filter.outputImage ?? ciImage
    }

    private func applyBlackAndWhite(to ciImage: CIImage) -> CIImage {
        let filter = CIFilter.colorMonochrome()
        filter.inputImage = ciImage
        filter.color = CIColor(color: .white)
        filter.intensity = 1.0
        return filter.outputImage ?? ciImage
    }

    private func applySharpen(to ciImage: CIImage) -> CIImage {
        let filter = CIFilter.sharpenLuminance()
        filter.inputImage = ciImage
        filter.sharpness = 0.8
        return filter.outputImage ?? ciImage
    }
}

enum ScannerError: LocalizedError {
    case pdfGenerationFailed
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .pdfGenerationFailed: return "Failed to generate PDF from scanned pages."
        case .saveFailed: return "Failed to save the scanned document."
        }
    }
}
