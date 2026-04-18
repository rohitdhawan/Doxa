import SwiftUI
import SwiftData

struct DocumentMetadataRow: View {
    let documentFileId: String
    @Query private var documents: [DocumentFile]

    init(documentFileId: String) {
        self.documentFileId = documentFileId
        _documents = Query(sort: \DocumentFile.importedAt)
    }

    private var document: DocumentFile? {
        documents.first { $0.id.uuidString == documentFileId }
    }

    var body: some View {
        if let doc = document {
            HStack(spacing: AppSpacing.md) {
                Label(formatFileSize(doc.fileSize), systemImage: "internaldrive")
                if let pages = doc.pageCount {
                    Label("\(pages) pg", systemImage: "doc.on.doc")
                }
                Label(doc.importedAt.formatted(.dateTime.month(.abbreviated).day()), systemImage: "calendar")
            }
            .font(.appMicro)
            .foregroundStyle(Color.appTextDim)
        }
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return "\(bytes / 1024) KB" }
        return String(format: "%.1f MB", Double(bytes) / (1024.0 * 1024.0))
    }
}
