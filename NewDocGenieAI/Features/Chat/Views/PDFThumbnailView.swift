import SwiftUI
import PDFKit
import SwiftData

struct PDFThumbnailView: View {
    let documentFileId: String
    @Query private var documents: [DocumentFile]
    @State private var thumbnail: UIImage?

    init(documentFileId: String) {
        self.documentFileId = documentFileId
        _documents = Query(sort: \DocumentFile.importedAt)
    }

    private var document: DocumentFile? {
        documents.first { $0.id.uuidString == documentFileId }
    }

    var body: some View {
        Group {
            if let image = thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "doc.richtext")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.appDanger)
            }
        }
        .frame(width: 56, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        .task { loadThumbnail() }
    }

    private func loadThumbnail() {
        guard let url = document?.fileURL else { return }
        guard let pdfDoc = PDFDocument(url: url),
              let page = pdfDoc.page(at: 0) else { return }
        let thumbSize = CGSize(width: 112, height: 144)
        thumbnail = page.thumbnail(of: thumbSize, for: .mediaBox)
    }
}
