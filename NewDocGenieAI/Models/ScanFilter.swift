import Foundation

enum ScanFilter: String, CaseIterable, Identifiable {
    case color = "Color"
    case grayscale = "Grayscale"
    case blackAndWhite = "B&W"
    case sharpen = "Sharp"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .color: return "paintpalette"
        case .grayscale: return "circle.lefthalf.filled"
        case .blackAndWhite: return "circle.fill"
        case .sharpen: return "sparkles"
        }
    }
}
