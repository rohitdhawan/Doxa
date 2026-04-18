import Foundation
import UniformTypeIdentifiers

enum AppConstants {
    static let appDocumentsSubdirectory = "NewDocGenieFiles"

    static let supportedExtensions: Set<String> = [
        "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx",
        "txt", "csv", "xml", "rtf",
        "jpg", "jpeg", "png", "heic", "webp", "bmp", "gif", "tiff"
    ]

    static let supportedUTTypes: [UTType] = [
        .pdf, .presentation, .spreadsheet, .plainText,
        .commaSeparatedText, .xml, .rtf, .image,
        .jpeg, .png, .heic, .webP, .bmp, .gif, .tiff,
        UTType("com.microsoft.word.doc") ?? .data,
        UTType("org.openxmlformats.wordprocessingml.document") ?? .data,
        UTType("com.microsoft.excel.xls") ?? .data,
        UTType("org.openxmlformats.spreadsheetml.sheet") ?? .data,
        UTType("com.microsoft.powerpoint.ppt") ?? .data,
        UTType("org.openxmlformats.presentationml.presentation") ?? .data,
    ]

    static let maxFileSizeBytes: Int64 = 500 * 1024 * 1024 // 500 MB
}
