import Foundation

struct PendingAttachment: Identifiable, Equatable {
    let id = UUID()
    let fileName: String
    let fileExtension: String
    let url: URL
    let iconSystemName: String

    var fullFileName: String {
        fileExtension.isEmpty ? fileName : "\(fileName).\(fileExtension)"
    }

    static func from(url: URL) -> PendingAttachment {
        let ext = url.pathExtension.lowercased()
        let name = (url.lastPathComponent as NSString).deletingPathExtension
        let icon = FileCategory.from(extension: ext).systemImage
        return PendingAttachment(
            fileName: name,
            fileExtension: ext,
            url: url,
            iconSystemName: icon
        )
    }

    static func == (lhs: PendingAttachment, rhs: PendingAttachment) -> Bool {
        lhs.id == rhs.id
    }
}
