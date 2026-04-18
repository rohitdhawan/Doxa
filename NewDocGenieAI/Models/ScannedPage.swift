import UIKit

struct ScannedPage: Identifiable {
    let id: UUID
    let originalImage: UIImage
    var currentImage: UIImage
    var appliedFilter: ScanFilter
    var rotation: Int

    init(image: UIImage) {
        self.id = UUID()
        self.originalImage = image
        self.currentImage = image
        self.appliedFilter = .color
        self.rotation = 0
    }
}
