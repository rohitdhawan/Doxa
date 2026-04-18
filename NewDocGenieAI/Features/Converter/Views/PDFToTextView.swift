import SwiftUI
import SwiftData

struct PDFToTextView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ConverterViewModel()
    @State private var selectedFiles: [DocumentFile] = []
    @State private var showPicker = false
    @State private var outputName = ""

    private var selectedFile: DocumentFile? { selectedFiles.first }

    var body: some View {
        NavigationStack {
            Group {
                if let text = viewModel.extractedText {
                    VStack(spacing: 0) {
                        HStack {
                            TextField("Output file name", text: $outputName)
                                .font(.appBody).autocorrectionDisabled()
                            Button("Save as TXT") {
                                viewModel.saveExtractedText(outputName: outputName, context: modelContext)
                            }
                            .font(.appCaption)
                            .foregroundStyle(Color.appPrimary)
                            .disabled(outputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .padding(AppSpacing.md)
                        .background(Color.appBGCard)

                        Divider()

                        ScrollView {
                            Text(text)
                                .font(.appMono)
                                .foregroundStyle(Color.appText)
                                .textSelection(.enabled)
                                .padding(AppSpacing.md)
                        }
                    }
                    .background(Color.appBGDark)
                } else if viewModel.isProcessing {
                    VStack(spacing: AppSpacing.md) {
                        ProgressView().scaleEffect(1.5)
                        Text("Extracting text...").font(.appBody).foregroundStyle(Color.appTextMuted)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appBGDark)
                } else {
                    Form {
                        Section("Select PDF") {
                            Button { showPicker = true } label: {
                                if let file = selectedFile {
                                    HStack {
                                        FileTypeIcon(fileExtension: "pdf")
                                        Text(file.fullFileName).font(.appBody).lineLimit(1)
                                    }
                                } else {
                                    Label("Choose a PDF", systemImage: "doc.richtext").font(.appBody)
                                }
                            }
                        }

                        Section {
                            Text("Extracts embedded text from PDF. For scanned documents, use OCR Text instead.")
                                .font(.appCaption).foregroundStyle(Color.appTextMuted)
                        }
                    }
                }
            }
            .navigationTitle("PDF to Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBGDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                if viewModel.extractedText == nil && !viewModel.isProcessing {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Extract") { extract() }
                            .disabled(selectedFile == nil)
                    }
                }
                if viewModel.extractedText != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            UIPasteboard.general.string = viewModel.extractedText
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }
                }
            }
            .sheet(isPresented: $showPicker) {
                PDFFilePickerView(title: "Select PDF", allowsMultiple: false, selectedFiles: $selectedFiles)
            }
            .onChange(of: selectedFiles) { _, _ in
                if let file = selectedFile { outputName = file.name }
            }
            .alert("Error", isPresented: $viewModel.showError) { Button("OK") {} } message: {
                Text(viewModel.errorMessage ?? "An error occurred.")
            }
        }
    }

    private func extract() {
        guard let url = selectedFile?.fileURL else { return }
        viewModel.pdfToText(url: url)
    }
}
