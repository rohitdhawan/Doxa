import SwiftUI
import SwiftData

struct DocumentViewerRouter: View {
    let file: DocumentFile
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DocumentViewerViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appBGDark)
            } else if let error = viewModel.errorMessage {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "Cannot Open File",
                    message: error
                )
                .background(Color.appBGDark)
            } else if let url = file.fileURL {
                switch file.viewerType {
                case .pdf:
                    PDFViewerView(url: url, fileName: file.fullFileName)
                case .image:
                    ImageViewerView(url: url, fileName: file.fullFileName)
                case .quickLook:
                    QuickLookViewerView(url: url, fileName: file.fullFileName)
                }
            }
        }
        .onAppear {
            viewModel.loadFile(file, context: modelContext)
        }
    }
}
