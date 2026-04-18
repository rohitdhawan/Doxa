import Foundation

struct InlineToolResult: Codable {
    let toolType: String
    let success: Bool
    let title: String
    let content: String
    var outputFileId: String?
    var outputFileName: String?
    var originalSize: Int64?
    var compressedSize: Int64?
}
