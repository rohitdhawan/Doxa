import SwiftUI
import SwiftData

struct OCRTextView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DocumentFile.importedAt, order: .reverse) private var allFiles: [DocumentFile]
    @State private var selectedFile: DocumentFile?
    @State private var showPicker = false
    @State private var extractedText = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showError = false

    private var selectableFiles: [DocumentFile] {
        allFiles.filter { ["pdf", "jpg", "jpeg", "png", "heic", "tiff", "bmp"].contains($0.fileExtension.lowercased()) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if extractedText.isEmpty && !isProcessing {
                    Form {
                        Section("Select File") {
                            Button { showPicker = true } label: {
                                if let file = selectedFile {
                                    HStack {
                                        FileTypeIcon(fileExtension: file.fileExtension)
                                        Text(file.fullFileName).font(.appBody).lineLimit(1)
                                    }
                                } else {
                                    Label("Choose a PDF or Image", systemImage: "text.viewfinder").font(.appBody)
                                }
                            }
                        }

                        Section {
                            Text("Select a PDF or image file to extract text using OCR (Optical Character Recognition).")
                                .font(.appCaption).foregroundStyle(Color.appTextMuted)
                        }
                    }
                } else if isProcessing {
                    VStack(spacing: AppSpacing.md) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Extracting text...")
                            .font(.appBody)
                            .foregroundStyle(Color.appTextMuted)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appBGDark)
                } else {
                    TextEditor(text: .constant(extractedText))
                        .font(.appMono)
                        .foregroundColor(Color.appText)
                        .scrollContentBackground(.hidden)
                        .background(Color.appBackground)
                        .padding(AppSpacing.sm)
                }
            }
            .navigationTitle("OCR Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        extractedText = ""
                        dismiss()
                    }
                }
                if extractedText.isEmpty && !isProcessing {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Extract") { extractText() }
                            .disabled(selectedFile == nil)
                    }
                }
                if !extractedText.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            UIPasteboard.general.string = extractedText
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }
                }
            }
            .sheet(isPresented: $showPicker) {
                OCRFilePickerSheet(files: selectableFiles, selectedFile: $selectedFile)
            }
            .alert("Error", isPresented: $showError) { Button("OK") {} } message: {
                Text(errorMessage ?? "An error occurred.")
            }
        }
    }

    private func extractText() {
        guard let url = selectedFile?.fileURL else { return }
        isProcessing = true
        Task {
            do {
                let text = try await OCRService.shared.extractText(from: url)
                extractedText = text
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isProcessing = false
        }
    }
}

private struct OCRFilePickerSheet: View {
    let files: [DocumentFile]
    @Binding var selectedFile: DocumentFile?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if files.isEmpty {
                    EmptyStateView(
                        icon: "text.viewfinder",
                        title: "No Files",
                        message: "Import PDF or image files first."
                    )
                } else {
                    List(files) { file in
                        Button {
                            selectedFile = file
                            dismiss()
                        } label: {
                            HStack(spacing: AppSpacing.md) {
                                FileTypeIcon(fileExtension: file.fileExtension)
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Text(file.fullFileName).font(.appBody).foregroundStyle(Color.appText).lineLimit(1)
                                    Text(file.fileSize.formattedFileSize).font(.appCaption).foregroundStyle(Color.appTextDim)
                                }
                                Spacer()
                                if selectedFile?.id == file.id {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.appPrimary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Select File")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}
