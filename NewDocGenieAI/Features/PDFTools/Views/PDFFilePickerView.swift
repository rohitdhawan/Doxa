import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct PDFFilePickerView: View {
    @Query(
        filter: #Predicate<DocumentFile> { $0.fileExtension == "pdf" },
        sort: \DocumentFile.importedAt,
        order: .reverse
    ) private var pdfFiles: [DocumentFile]

    let title: String
    let allowsMultiple: Bool
    @Binding var selectedFiles: [DocumentFile]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showDocumentPicker = false
    @State private var errorMessage: String?
    @State private var showError = false

    private let importService = FileImportService()

    var body: some View {
        NavigationStack {
            Group {
                if pdfFiles.isEmpty {
                    VStack(spacing: AppSpacing.lg) {
                        EmptyStateView(
                            icon: "doc.richtext",
                            title: "No PDFs",
                            message: "Choose a PDF from this app or import one directly from your device."
                        )

                        deviceImportButton
                            .padding(.horizontal, AppSpacing.xl)
                    }
                } else {
                    List(pdfFiles) { file in
                        Button {
                            toggleSelection(file)
                        } label: {
                            HStack(spacing: AppSpacing.md) {
                                FileTypeIcon(fileExtension: file.fileExtension)

                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Text(file.fullFileName)
                                        .font(.appBody)
                                        .foregroundStyle(Color.appText)
                                        .lineLimit(1)

                                    HStack(spacing: AppSpacing.sm) {
                                        if let pages = file.pageCount {
                                            Text("\(pages) pages")
                                                .font(.appCaption)
                                                .foregroundStyle(Color.appTextDim)
                                        }
                                        Text(file.fileSize.formattedFileSize)
                                            .font(.appCaption)
                                            .foregroundStyle(Color.appTextDim)
                                    }
                                }

                                Spacer()

                                if isSelected(file) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.appPrimary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .safeAreaInset(edge: .bottom) {
                        deviceImportButton
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.top, AppSpacing.sm)
                            .background(Color.appBackground)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPickerView(
                    contentTypes: [.pdf],
                    allowsMultipleSelection: allowsMultiple
                ) { urls in
                    importFromDevice(urls: urls)
                }
            }
            .alert("Import Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "Failed to import PDF.")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        selectedFiles = []
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .disabled(selectedFiles.isEmpty)
                }
            }
        }
    }

    private var deviceImportButton: some View {
        Button {
            showDocumentPicker = true
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "iphone.gen3")
                    .font(.appBody.weight(.semibold))

                Text(allowsMultiple ? "Choose PDFs From Device" : "Choose PDF From Device")
                    .font(.appBody.weight(.semibold))
            }
            .foregroundStyle(Color.appPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(Color.appBGElevated, in: RoundedRectangle(cornerRadius: AppCornerRadius.lg))
        }
        .buttonStyle(.plain)
    }

    private func isSelected(_ file: DocumentFile) -> Bool {
        selectedFiles.contains { $0.id == file.id }
    }

    private func toggleSelection(_ file: DocumentFile) {
        if allowsMultiple {
            if let index = selectedFiles.firstIndex(where: { $0.id == file.id }) {
                selectedFiles.remove(at: index)
            } else {
                selectedFiles.append(file)
            }
        } else {
            selectedFiles = [file]
            dismiss()
        }
    }

    private func importFromDevice(urls: [URL]) {
        guard !urls.isEmpty else { return }

        do {
            let importedFiles = try importService.importFiles(from: urls, into: modelContext)

            if allowsMultiple {
                let existingIDs = Set(selectedFiles.map(\.id))
                let newFiles = importedFiles.filter { !existingIDs.contains($0.id) }
                selectedFiles.append(contentsOf: newFiles)
            } else if let file = importedFiles.first {
                selectedFiles = [file]
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
