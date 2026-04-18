import SwiftUI
import SwiftData

struct DocToPDFView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DocumentFile.importedAt, order: .reverse) private var allFiles: [DocumentFile]
    @State private var viewModel = ConverterViewModel()
    @State private var selectedFile: DocumentFile?
    @State private var showPicker = false
    @State private var outputName = ""

    private var convertibleFiles: [DocumentFile] {
        allFiles.filter {
            ["doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "csv", "xml", "rtf"].contains($0.fileExtension.lowercased())
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Select Document") {
                    Button { showPicker = true } label: {
                        if let file = selectedFile {
                            HStack {
                                FileTypeIcon(fileExtension: file.fileExtension)
                                VStack(alignment: .leading) {
                                    Text(file.fullFileName).font(.appBody).lineLimit(1)
                                    Text(file.fileExtension.uppercased()).font(.appCaption).foregroundStyle(Color.appTextDim)
                                }
                            }
                        } else {
                            Label("Choose a document", systemImage: "doc.text").font(.appBody)
                        }
                    }
                }

                Section("Output Name") {
                    TextField("Converted document", text: $outputName)
                        .font(.appBody).autocorrectionDisabled()
                }

                Section {
                    Text("Supported: DOC, DOCX, XLS, XLSX, PPT, PPTX, TXT, CSV, XML, RTF")
                        .font(.appCaption).foregroundStyle(Color.appTextMuted)
                }

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
            .navigationTitle("Doc to PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBGDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isProcessing { ProgressView() }
                    else if viewModel.didComplete { Button("Done") { dismiss() } }
                    else {
                        Button("Convert") { convert() }
                            .disabled(selectedFile == nil || outputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .sheet(isPresented: $showPicker) {
                DocFilePickerSheet(files: convertibleFiles, selectedFile: $selectedFile)
            }
            .onChange(of: selectedFile) { _, file in
                if let file { outputName = file.name }
            }
            .alert("Error", isPresented: $viewModel.showError) { Button("OK") {} } message: {
                Text(viewModel.errorMessage ?? "An error occurred.")
            }
            .confettiOnComplete(viewModel.didComplete)
        }
    }

    private func convert() {
        guard let url = selectedFile?.fileURL else { return }
        viewModel.documentToPDF(url: url, outputName: outputName, context: modelContext)
    }
}

private struct DocFilePickerSheet: View {
    let files: [DocumentFile]
    @Binding var selectedFile: DocumentFile?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if files.isEmpty {
                    EmptyStateView(icon: "doc.text", title: "No Documents", message: "Import document files first.")
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
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Select Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBGDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}
