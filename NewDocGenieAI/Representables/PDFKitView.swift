import SwiftUI
import PDFKit

struct PDFKitView: UIViewRepresentable {
    let url: URL
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    var goToPage: Int? = nil
    var highlightSelection: PDFSelection? = nil

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor(Color.appBGDark)

        if let document = PDFDocument(url: url) {
            pdfView.document = document
            DispatchQueue.main.async {
                totalPages = document.pageCount
                currentPage = 1
            }
        }

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // Navigate to page
        if let goTo = goToPage,
           let document = uiView.document,
           goTo >= 1, goTo <= document.pageCount {
            if let page = document.page(at: goTo - 1) {
                let currentIdx = uiView.currentPage.flatMap { document.index(for: $0) } ?? -1
                if currentIdx != goTo - 1 {
                    uiView.go(to: page)
                }
            }
        }

        // Highlight search selection
        uiView.highlightedSelections = nil
        if let selection = highlightSelection {
            uiView.highlightedSelections = [selection]
            uiView.setCurrentSelection(selection, animate: true)
            if let page = selection.pages.first {
                uiView.go(to: page)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    @MainActor
    class Coordinator: NSObject {
        let parent: PDFKitView

        init(parent: PDFKitView) {
            self.parent = parent
        }

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPage = pdfView.currentPage,
                  let pageIndex = pdfView.document?.index(for: currentPage) else { return }
            parent.currentPage = pageIndex + 1
        }
    }
}
