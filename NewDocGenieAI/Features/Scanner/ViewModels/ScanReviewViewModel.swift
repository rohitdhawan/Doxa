import SwiftUI
import SwiftData

@MainActor
@Observable
final class ScanReviewViewModel {
    var pages: [ScannedPage] = []
    var selectedPageIndex: Int = 0
    var selectedFilter: ScanFilter = .color
    var fileName: String = ""
    var isSaving = false
    var didSave = false
    var savedDocumentId: String?
    var errorMessage: String?
    var showError = false

    private let scannerService = ScannerService.shared

    func loadScannedImages(_ images: [UIImage]) {
        pages = images.map { ScannedPage(image: $0) }
        fileName = "Scan \(Date.now.formatted(.dateTime.month(.abbreviated).day().hour().minute()))"
    }

    var currentPage: ScannedPage? {
        guard pages.indices.contains(selectedPageIndex) else { return nil }
        return pages[selectedPageIndex]
    }

    var pageCountText: String {
        "\(selectedPageIndex + 1) / \(pages.count)"
    }

    // MARK: - Filter

    func applyFilter(_ filter: ScanFilter) {
        guard pages.indices.contains(selectedPageIndex) else { return }
        selectedFilter = filter
        pages[selectedPageIndex].appliedFilter = filter
        pages[selectedPageIndex].currentImage = scannerService.applyFilter(
            filter,
            to: pages[selectedPageIndex].originalImage
        )
    }

    // MARK: - Rotation

    func rotateCurrentPage() {
        guard pages.indices.contains(selectedPageIndex) else { return }
        pages[selectedPageIndex].rotation = (pages[selectedPageIndex].rotation + 90) % 360
        pages[selectedPageIndex].currentImage = scannerService.rotateImage(
            pages[selectedPageIndex].currentImage,
            by: 90
        )
    }

    // MARK: - Page Management

    func deletePage(at index: Int) {
        guard pages.indices.contains(index), pages.count > 1 else { return }
        pages.remove(at: index)
        if selectedPageIndex >= pages.count {
            selectedPageIndex = pages.count - 1
        }
    }

    func deleteCurrentPage() {
        deletePage(at: selectedPageIndex)
    }

    func movePage(from source: IndexSet, to destination: Int) {
        pages.move(fromOffsets: source, toOffset: destination)
    }

    func selectPage(at index: Int) {
        guard pages.indices.contains(index) else { return }
        selectedPageIndex = index
        selectedFilter = pages[index].appliedFilter
    }

    // MARK: - Save

    @MainActor
    func saveScan(into modelContext: ModelContext) {
        isSaving = true
        do {
            let result = try scannerService.saveScanAsPDF(pages: pages, fileName: fileName)
            let metadata = FileMetadataService.shared.extractMetadata(from: result.url)

            let docFile = DocumentFile(
                name: (result.url.lastPathComponent as NSString).deletingPathExtension,
                fileExtension: "pdf",
                relativeFilePath: result.relativePath,
                fileSize: metadata.fileSize,
                pageCount: pages.count
            )
            modelContext.insert(docFile)
            try modelContext.save()
            savedDocumentId = docFile.id.uuidString
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isSaving = false
    }
}
