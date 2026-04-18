import SwiftUI
import SwiftData
import TipKit

struct FilesTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DocumentFile.importedAt, order: .reverse) private var allFiles: [DocumentFile]
    @State private var viewModel = FilesViewModel()
    @State private var actionsVM = FileActionsViewModel()

    @State private var selectedFile: DocumentFile?
    @State private var fileToRename: DocumentFile?
    @State private var fileToShowInfo: DocumentFile?
    @State private var fileToDelete: DocumentFile?
    @State private var showDeleteConfirmation = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isInitialLoad = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    TipView(ScanCompleteTip())
                        .tipBackground(Color.appBGCard)
                        .tint(Color.appPrimary)
                        .padding(.horizontal, AppSpacing.md)

                    // Search bar
                    AppSearchBar(text: $viewModel.searchText)
                        .padding(.horizontal, AppSpacing.md)

                    // Category filter
                    FileCategoryGridView(
                        files: allFiles,
                        selectedCategory: $viewModel.selectedCategory,
                        viewModel: viewModel
                    )
                    .padding(.horizontal, AppSpacing.md)

                    // Sort header
                    HStack {
                        Text("\(filteredFiles.count) files")
                            .font(.appCaption)
                            .foregroundStyle(Color.appTextMuted)
                        Spacer()
                        SortMenuButton(selectedSort: $viewModel.sortOption)
                    }
                    .padding(.horizontal, AppSpacing.md)

                    if isInitialLoad {
                        SkeletonList(count: 5)
                    } else if filteredFiles.isEmpty && !viewModel.searchText.isEmpty {
                        // Search empty state
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No Results",
                            message: "No files match \"\(viewModel.searchText)\". Try a different search term."
                        )
                        .frame(maxHeight: .infinity)
                    } else {
                        // File list
                        FileListView(
                            files: filteredFiles,
                            onSelect: { file in
                                file.lastOpenedAt = Date()
                                try? modelContext.save()
                                selectedFile = file
                            },
                            onAction: { file, action in
                                handleAction(action, for: file)
                            }
                        )
                        .padding(.horizontal, AppSpacing.md)
                    }
                }
                .padding(.vertical, AppSpacing.sm)
            }
            .refreshable {
                HapticManager.light()
                try? await Task.sleep(for: .milliseconds(400))
            }
            .background(Color.appBGDark)
            .task {
                try? await Task.sleep(for: .milliseconds(300))
                withAnimation(.easeOut(duration: 0.3)) { isInitialLoad = false }
            }
            .navigationTitle("Files")
            .toolbarBackground(Color.appBGDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    FileImportButton()
                }
            }
            .navigationDestination(item: $selectedFile) { file in
                DocumentViewerRouter(file: file)
            }
            .sheet(item: $fileToRename) { file in
                FileRenameSheet(file: file) { newName in
                    do {
                        try actionsVM.rename(file, to: newName, context: modelContext)
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
            .sheet(item: $fileToShowInfo) { file in
                FileDetailSheet(file: file)
            }
            .alert("Delete File?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { fileToDelete = nil }
                Button("Delete", role: .destructive) {
                    guard let file = fileToDelete else { return }
                    do {
                        try actionsVM.delete(file, context: modelContext)
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                    fileToDelete = nil
                }
            } message: {
                Text("This will permanently remove \"\(fileToDelete?.fullFileName ?? "")\" from the app.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "An unexpected error occurred.")
            }
        }
    }

    private var filteredFiles: [DocumentFile] {
        viewModel.filteredAndSorted(allFiles)
    }

    private func handleAction(_ action: FileRowAction, for file: DocumentFile) {
        switch action {
        case .rename:
            fileToRename = file
        case .delete:
            fileToDelete = file
            showDeleteConfirmation = true
        case .share:
            actionsVM.share(file)
        case .info:
            fileToShowInfo = file
        case .toggleFavorite:
            do {
                try actionsVM.toggleFavorite(file, context: modelContext)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
