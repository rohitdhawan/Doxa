import SwiftUI

struct FileTypeIcon: View {
    let fileExtension: String
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                .fill(iconColor.opacity(0.15))
                .frame(width: size, height: size)

            Image(systemName: iconName)
                .font(.system(size: size * 0.45))
                .foregroundStyle(iconColor)
        }
    }

    private var iconName: String {
        switch fileExtension.lowercased() {
        case "pdf": return "doc.richtext"
        case "doc", "docx": return "doc.text"
        case "xls", "xlsx": return "tablecells"
        case "ppt", "pptx": return "play.rectangle"
        case "txt", "rtf": return "doc.plaintext"
        case "csv": return "tablecells"
        case "xml": return "chevron.left.forwardslash.chevron.right"
        case "jpg", "jpeg", "png", "heic", "webp", "bmp", "gif", "tiff":
            return "photo"
        default: return "doc"
        }
    }

    private var iconColor: Color {
        switch fileExtension.lowercased() {
        case "pdf": return .appDanger
        case "doc", "docx": return .appPrimary
        case "xls", "xlsx": return .appSuccess
        case "ppt", "pptx": return .appWarning
        case "txt", "rtf", "csv", "xml": return .appTextMuted
        case "jpg", "jpeg", "png", "heic", "webp", "bmp", "gif", "tiff":
            return .appAccent
        default: return .appTextDim
        }
    }
}
