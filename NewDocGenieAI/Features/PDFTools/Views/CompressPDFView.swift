import SwiftUI
import SwiftData

struct CompressPDFView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PDFToolsViewModel()
    @State private var selectedFiles: [DocumentFile] = []
    @State private var showPicker = false
    @State private var compressionLevel: PDFToolsService.CompressionLevel = .medium
    @State private var outputName = ""

    private var selectedFile: DocumentFile? { selectedFiles.first }

    var body: some View {
        NavigationStack {
            Form {
                Section("Select PDF") {
                    Button {
                        showPicker = true
                    } label: {
                        if let file = selectedFile {
                            HStack {
                                FileTypeIcon(fileExtension: "pdf")
                                VStack(alignment: .leading) {
                                    Text(file.fullFileName)
                                        .font(.appBody)
                                        .lineLimit(1)
                                    Text(file.fileSize.formattedFileSize)
                                        .font(.appCaption)
                                        .foregroundStyle(Color.appTextDim)
                                }
                            }
                        } else {
                            Label("Choose a PDF", systemImage: "doc.richtext")
                                .font(.appBody)
                        }
                    }
                }

                Section("Compression Level") {
                    ForEach(PDFToolsService.CompressionLevel.allCases) { level in
                        Button {
                            compressionLevel = level
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(level.rawValue)
                                        .font(.appBody)
                                        .foregroundStyle(Color.appText)
                                    Text(level.description)
                                        .font(.appCaption)
                                        .foregroundStyle(Color.appTextMuted)
                                }
                                Spacer()
                                if compressionLevel == level {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.appPrimary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Output Name") {
                    TextField("Compressed document", text: $outputName)
                        .font(.appBody)
                        .autocorrectionDisabled()
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
            .navigationTitle("Compress PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBGDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isProcessing {
                        ProgressView()
                    } else if viewModel.didComplete {
                        Button("Done") { dismiss() }
                    } else {
                        Button("Compress") { compress() }
                            .disabled(selectedFile == nil || outputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .sheet(isPresented: $showPicker) {
                PDFFilePickerView(
                    title: "Select PDF",
                    allowsMultiple: false,
                    selectedFiles: $selectedFiles
                )
            }
            .onChange(of: selectedFiles) { _, _ in
                if let file = selectedFile {
                    outputName = "\(file.name) (compressed)"
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred.")
            }
            .confettiOnComplete(viewModel.didComplete)
        }
    }

    private func compress() {
        guard let url = selectedFile?.fileURL else { return }
        viewModel.compressPDF(url: url, level: compressionLevel, outputName: outputName, context: modelContext)
    }
}
