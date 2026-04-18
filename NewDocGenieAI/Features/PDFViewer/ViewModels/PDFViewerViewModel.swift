import SwiftUI
import PDFKit

@MainActor
@Observable
final class PDFViewerViewModel {
    // MARK: - State
    var pdfDocument: PDFDocument?
    var pdfURL: URL?
    var currentPage: Int = 0
    var totalPages: Int = 0
    var isLoading = false

    // Search
    var searchText = ""
    var searchResults: [PDFSelection] = []
    var currentSearchIndex: Int = 0
    var isSearching = false

    // Thumbnails
    var thumbnails: [UIImage] = []
    var isGeneratingThumbnails = false

    // Sheets
    var showFilePicker = false
    var showThumbnails = false
    var showSearch = false
    var showShareSheet = false
    var showScanner = false
    var showScanReview = false
    var scannedImages: [UIImage] = []

    // Sub-tools
    var activeSubTool: ToolItem?

    // Error
    var errorMessage: String?
    var showError = false

    // MARK: - Computed
    var hasDocument: Bool { pdfDocument != nil }

    var currentSearchResult: PDFSelection? {
        guard !searchResults.isEmpty, currentSearchIndex < searchResults.count else { return nil }
        return searchResults[currentSearchIndex]
    }

    var searchStatusText: String {
        if searchResults.isEmpty {
            return isSearching ? "Searching..." : "No results"
        }
        return "\(currentSearchIndex + 1) of \(searchResults.count)"
    }

    // MARK: - Load PDF
    func loadPDF(url: URL) {
        isLoading = true
        pdfURL = url

        if let document = PDFDocument(url: url) {
            pdfDocument = document
            totalPages = document.pageCount
            currentPage = document.pageCount > 0 ? 1 : 0
            generateThumbnails()
        } else {
            errorMessage = "Unable to open PDF file."
            showError = true
        }

        isLoading = false
    }

    // MARK: - Search
    func performSearch() {
        guard let document = pdfDocument else { return }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            currentSearchIndex = 0
            return
        }

        isSearching = true
        let results = document.findString(query, withOptions: .caseInsensitive)
        searchResults = results
        currentSearchIndex = results.isEmpty ? 0 : 0
        isSearching = false
    }

    func nextSearchResult() {
        guard !searchResults.isEmpty else { return }
        currentSearchIndex = (currentSearchIndex + 1) % searchResults.count
    }

    func previousSearchResult() {
        guard !searchResults.isEmpty else { return }
        currentSearchIndex = (currentSearchIndex - 1 + searchResults.count) % searchResults.count
    }

    func clearSearch() {
        searchText = ""
        searchResults = []
        currentSearchIndex = 0
    }

    // MARK: - Thumbnails
    func generateThumbnails() {
        guard let document = pdfDocument else { return }
        isGeneratingThumbnails = true
        thumbnails = []

        let thumbnailSize = CGSize(width: 120, height: 160)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var generated: [UIImage] = []
            for i in 0..<document.pageCount {
                if let page = document.page(at: i) {
                    let thumb = page.thumbnail(of: thumbnailSize, for: .cropBox)
                    generated.append(thumb)
                }
            }

            DispatchQueue.main.async {
                self?.thumbnails = generated
                self?.isGeneratingThumbnails = false
            }
        }
    }

    // MARK: - Page Navigation
    func goToPage(_ page: Int) {
        guard let document = pdfDocument,
              page >= 1, page <= document.pageCount else { return }
        currentPage = page
    }
}
