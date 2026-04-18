import UIKit
import PDFKit

@MainActor
final class ThumbnailService {
    static let shared = ThumbnailService()
    private let cache = NSCache<NSURL, UIImage>()

    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }

    func thumbnail(for url: URL, size: CGSize = CGSize(width: 80, height: 80)) -> UIImage? {
        let key = url as NSURL
        if let cached = cache.object(forKey: key) {
            return cached
        }

        guard let document = PDFDocument(url: url),
              let page = document.page(at: 0) else {
            return nil
        }

        let image = page.thumbnail(of: size, for: .mediaBox)
        cache.setObject(image, forKey: key)
        return image
    }

    func clearCache() {
        cache.removeAllObjects()
    }
}
