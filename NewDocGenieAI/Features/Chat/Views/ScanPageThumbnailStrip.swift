import SwiftUI
import PDFKit
import SwiftData

struct ScanPageThumbnailStrip: View {
    let documentFileId: String
    let pageCount: Int
    @Query private var documents: [DocumentFile]
    @State private var thumbnails: [UIImage] = []

    private let maxVisible = 4

    init(documentFileId: String, pageCount: Int) {
        self.documentFileId = documentFileId
        self.pageCount = pageCount
        _documents = Query(sort: \DocumentFile.importedAt)
    }

    private var document: DocumentFile? {
        documents.first { $0.id.uuidString == documentFileId }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(Array(thumbnails.enumerated()), id: \.offset) { _, image in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                }

                if pageCount > thumbnails.count && !thumbnails.isEmpty {
                    Text("+\(pageCount - thumbnails.count)")
                        .font(.appMicro)
                        .foregroundStyle(Color.appTextMuted)
                        .frame(width: 44, height: 56)
                        .background(Color.appBGCard, in: RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                }
            }
        }
        .frame(height: 56)
        .task { loadThumbnails() }
    }

    private func loadThumbnails() {
        guard let url = document?.fileURL,
              let pdfDoc = PDFDocument(url: url) else { return }

        let count = min(pageCount, maxVisible)
        var images: [UIImage] = []
        let thumbSize = CGSize(width: 88, height: 112)

        for i in 0..<count {
            guard let page = pdfDoc.page(at: i) else { continue }
            images.append(page.thumbnail(of: thumbSize, for: .mediaBox))
        }
        thumbnails = images
    }
}
