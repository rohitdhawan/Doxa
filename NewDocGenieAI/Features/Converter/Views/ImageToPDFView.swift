import SwiftUI
import SwiftData
import PhotosUI

struct ImageToPDFView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DocumentFile.importedAt, order: .reverse) private var allFiles: [DocumentFile]
    @State private var viewModel = ConverterViewModel()
    @State private var selectedFiles: [DocumentFile] = []
    @State private var selectedImageURLs: [URL] = []
    @State private var showSourcePicker = false
    @State private var showAppFilePicker = false
    @State private var showDocumentPicker = false
    @State private var showPhotoPicker = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var outputName = ""

    private var imageFiles: [DocumentFile] {
        allFiles.filter { ["jpg", "jpeg", "png", "heic", "bmp", "gif", "tiff", "webp"].contains($0.fileExtension.lowercased()) }
    }

    private var totalImageCount: Int {
        selectedFiles.count + selectedImageURLs.count
    }

    var body: some View {
        NavigationStack {
            Form {
                imageSelectionSection
                outputNameSection
                completionSection
            }
            .navigationTitle("Image to PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBGDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar { toolbarContent }
            .confirmationDialog("Choose Image Source", isPresented: $showSourcePicker) {
                Button("Photo Library") { showPhotoPicker = true }
                Button("Browse Files") { showDocumentPicker = true }
                Button("App Files") { showAppFilePicker = true }
                Button("Cancel", role: .cancel) {}
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotos, matching: .images)
            .onChange(of: selectedPhotos) { _, newItems in
                handlePhotoSelection(items: newItems)
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPickerView(contentTypes: [.image]) { urls in
                    handleDocumentPickerResult(urls: urls)
                }
            }
            .sheet(isPresented: $showAppFilePicker) {
                ImageFilePickerSheet(files: imageFiles, selectedFiles: $selectedFiles)
            }
            .alert("Error", isPresented: $viewModel.showError) { Button("OK") {} } message: {
                Text(viewModel.errorMessage ?? "An error occurred.")
            }
            .confettiOnComplete(viewModel.didComplete)
        }
    }

    // MARK: - Sections

    private var imageSelectionSection: some View {
        Section("Select Images") {
            Button { showSourcePicker = true } label: {
                Label(chooseButtonTitle, systemImage: "photo.on.rectangle")
                    .font(.appBody)
            }

            ForEach(selectedFiles) { file in
                selectedFileRow(file: file)
            }

            ForEach(selectedImageURLs, id: \.absoluteString) { url in
                selectedURLRow(url: url)
            }
        }
    }

    private var chooseButtonTitle: String {
        totalImageCount == 0 ? "Choose images" : "\(totalImageCount) image\(totalImageCount == 1 ? "" : "s") selected"
    }

    private func selectedFileRow(file: DocumentFile) -> some View {
        HStack {
            FileTypeIcon(fileExtension: file.fileExtension)
            Text(file.fullFileName).font(.appBody).lineLimit(1)
            Spacer()
            Button {
                selectedFiles.removeAll { $0.id == file.id }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.appTextMuted)
            }
        }
    }

    private func selectedURLRow(url: URL) -> some View {
        HStack {
            urlThumbnail(url: url)
            Text(url.lastPathComponent).font(.appBody).lineLimit(1)
            Spacer()
            Button {
                selectedImageURLs.removeAll { $0 == url }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.appTextMuted)
            }
        }
    }

    @ViewBuilder
    private func urlThumbnail(url: URL) -> some View {
        if let uiImage = UIImage(contentsOfFile: url.path) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            Image(systemName: "photo")
                .foregroundStyle(Color.appPrimary)
                .frame(width: 36, height: 36)
        }
    }

    private var outputNameSection: some View {
        Section("Output Name") {
            TextField("Combined images", text: $outputName)
                .font(.appBody).autocorrectionDisabled()
        }
    }

    @ViewBuilder
    private var completionSection: some View {
        if viewModel.didComplete, let name = viewModel.resultFileName {
            Section {
                VStack(spacing: AppSpacing.sm) {
                    AnimatedCheckmark()
                    Text("Saved as \(name)")
                        .font(.appBody)
                        .foregroundStyle(Color.appSuccess)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.appSuccess.opacity(0.05))
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
        ToolbarItem(placement: .confirmationAction) {
            if viewModel.isProcessing { ProgressView() }
            else if viewModel.didComplete { Button("Done") { dismiss() } }
            else {
                Button("Convert") { convert() }
                    .disabled(totalImageCount == 0 || outputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func handleDocumentPickerResult(urls: [URL]) {
        for url in urls {
            let didAccess = url.startAccessingSecurityScopedResource()
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + "_" + url.lastPathComponent)
            try? FileManager.default.copyItem(at: url, to: tempURL)
            if didAccess { url.stopAccessingSecurityScopedResource() }
            if !selectedImageURLs.contains(tempURL) {
                selectedImageURLs.append(tempURL)
            }
        }
    }

    private func handlePhotoSelection(items: [PhotosPickerItem]) {
        Task {
            for item in items {
                guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString + ".jpg")
                try? data.write(to: tempURL)
                await MainActor.run {
                    selectedImageURLs.append(tempURL)
                }
            }
            await MainActor.run {
                selectedPhotos = []
            }
        }
    }

    private func convert() {
        // Combine URLs from both sources
        var urls = selectedFiles.compactMap { $0.fileURL }
        urls.append(contentsOf: selectedImageURLs)
        guard !urls.isEmpty else { return }
        viewModel.imagesToPDF(urls: urls, outputName: outputName, context: modelContext)
    }
}

private struct ImageFilePickerSheet: View {
    let files: [DocumentFile]
    @Binding var selectedFiles: [DocumentFile]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if files.isEmpty {
                    EmptyStateView(icon: "photo", title: "No Images", message: "Import image files first from the Files tab.")
                } else {
                    List(files) { file in
                        Button {
                            if let idx = selectedFiles.firstIndex(where: { $0.id == file.id }) {
                                selectedFiles.remove(at: idx)
                            } else {
                                selectedFiles.append(file)
                            }
                        } label: {
                            HStack(spacing: AppSpacing.md) {
                                FileTypeIcon(fileExtension: file.fileExtension)
                                Text(file.fullFileName).font(.appBody).foregroundStyle(Color.appText).lineLimit(1)
                                Spacer()
                                if selectedFiles.contains(where: { $0.id == file.id }) {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.appPrimary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("App Files")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBGDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.disabled(selectedFiles.isEmpty) }
            }
        }
    }
}
