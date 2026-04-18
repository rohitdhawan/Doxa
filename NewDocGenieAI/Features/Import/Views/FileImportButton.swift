import SwiftUI
import SwiftData
import PhotosUI

struct FileImportButton: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showDocumentPicker = false
    @State private var showPhotoPicker = false
    @State private var showSourcePicker = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var errorMessage: String?
    @State private var showError = false

    private let importService = FileImportService()

    var body: some View {
        Button {
            showSourcePicker = true
        } label: {
            Label("Open", systemImage: "plus")
                .font(.appH3)
                .foregroundStyle(Color.appPrimary)
        }
        .confirmationDialog("Import From", isPresented: $showSourcePicker) {
            Button("Browse Files") {
                showDocumentPicker = true
            }
            Button("Photo Library") {
                showPhotoPicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerView { urls in
                importFromPicker(urls: urls)
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotos, matching: .images)
        .onChange(of: selectedPhotos) { _, newItems in
            importFromPhotos(items: newItems)
        }
        .alert("Import Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "Failed to import file.")
        }
    }

    private func importFromPicker(urls: [URL]) {
        do {
            _ = try importService.importFiles(from: urls, into: modelContext)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func importFromPhotos(items: [PhotosPickerItem]) {
        Task {
            for item in items {
                guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString + ".jpg")
                try? data.write(to: tempURL)
                do {
                    _ = try importService.importFiles(from: [tempURL], into: modelContext)
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                }
                try? FileManager.default.removeItem(at: tempURL)
            }
            selectedPhotos = []
        }
    }
}
