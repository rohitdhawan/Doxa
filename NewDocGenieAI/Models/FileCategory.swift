import Foundation

enum FileCategory: String, CaseIterable, Identifiable {
    case all
    case pdf
    case doc
    case xls
    case ppt
    case txt
    case img

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All"
        case .pdf: return "PDF"
        case .doc: return "Doc"
        case .xls: return "XLS"
        case .ppt: return "PPT"
        case .txt: return "TXT"
        case .img: return "IMG"
        }
    }

    var systemImage: String {
        switch self {
        case .all: return "doc.on.doc"
        case .pdf: return "doc.richtext"
        case .doc: return "doc.text"
        case .xls: return "tablecells"
        case .ppt: return "play.rectangle"
        case .txt: return "doc.plaintext"
        case .img: return "photo"
        }
    }

    var extensions: Set<String> {
        switch self {
        case .all: return AppConstants.supportedExtensions
        case .pdf: return ["pdf"]
        case .doc: return ["doc", "docx"]
        case .xls: return ["xls", "xlsx"]
        case .ppt: return ["ppt", "pptx"]
        case .txt: return ["txt", "csv", "xml", "rtf"]
        case .img: return ["jpg", "jpeg", "png", "heic", "webp", "bmp", "gif", "tiff"]
        }
    }

    static func from(extension ext: String) -> FileCategory {
        let lower = ext.lowercased()
        for category in FileCategory.allCases where category != .all {
            if category.extensions.contains(lower) {
                return category
            }
        }
        return .all
    }
}
