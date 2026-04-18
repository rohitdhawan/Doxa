import SwiftUI
import SwiftData
import TipKit

struct ScanReviewView: View {
    let scannedImages: [UIImage]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ScanReviewViewModel()
    @State private var showSaveSheet = false
    @State private var showPageManager = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScanPagePreview(page: viewModel.currentPage)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text(viewModel.pageCountText)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextMuted)
                    .padding(.vertical, AppSpacing.xs)

                if viewModel.pages.count > 1 {
                    ScanPageStripView(
                        pages: viewModel.pages,
                        selectedIndex: viewModel.selectedPageIndex,
                        onSelect: { index in viewModel.selectPage(at: index) }
                    )
                }

                ScanFilterBar(
                    selectedFilter: viewModel.selectedFilter,
                    onFilterSelect: { filter in viewModel.applyFilter(filter) }
                )

                ScanActionBar(
                    onRotate: { viewModel.rotateCurrentPage() },
                    onDelete: { viewModel.deleteCurrentPage() },
                    onReorder: { showPageManager = true },
                    canDelete: viewModel.pages.count > 1
                )
            }
            .background(Color.appBGDark)
            .navigationTitle("Review Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBGDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") { dismiss() }
                        .foregroundStyle(Color.appDanger)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { showSaveSheet = true }
                        .foregroundStyle(Color.appPrimary)
                }
            }
            .sheet(isPresented: $showSaveSheet) {
                ScanSaveSheet(viewModel: viewModel) {
                    viewModel.saveScan(into: modelContext)
                    if viewModel.didSave {
                        Task { await ScanCompleteTip.scanCompleted.donate() }
                        showSaveSheet = false
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPageManager) {
                ScanPageManagerSheet(viewModel: viewModel)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "An unexpected error occurred.")
            }
            .onAppear {
                viewModel.loadScannedImages(scannedImages)
            }
        }
    }
}
