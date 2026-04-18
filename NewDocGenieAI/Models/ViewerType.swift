import Foundation

enum ViewerType: Equatable {
    case pdf
    case image
    case quickLook

    static func from(extension ext: String) -> ViewerType {
        switch ext.lowercased() {
        case "pdf":
            return .pdf
        case "jpg", "jpeg", "png", "heic", "webp", "bmp", "gif", "tiff":
            return .image
        default:
            return .quickLook
        }
    }
}
