import SwiftUI
import SwiftData

struct MetadataEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PDFToolsViewModel()
    @State private var selectedFiles: [DocumentFile] = []
    @State private var showPicker = false
    @State private var title = ""
    @State private var author = ""
    @State private var subject = ""
    @State private var keywords = ""
    @State private var outputName = ""

    private var selectedFile: DocumentFile? { selectedFiles.first }

    var body: some View {
        NavigationStack {
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

                if selectedFile != nil {
                    Section("Metadata") {
                        TextField("Title", text: $title).font(.appBody)
                        TextField("Author", text: $author).font(.appBody)
                        TextField("Subject", text: $subject).font(.appBody)
                        TextField("Keywords (comma separated)", text: $keywords).font(.appBody)
                        Text("Leave fields blank to remove them.")
                            .font(.appCaption).foregroundStyle(Color.appTextMuted)
                    }

                    Section("Output Name") {
                        TextField("Updated document", text: $outputName)
                            .font(.appBody).autocorrectionDisabled()
                    }
                }

                if viewModel.didComplete, let name = viewModel.resultFileName {
                    Section {
                        VStack(spacing: AppSpacing.sm) {
                            AnimatedCheckmark()
                            Text("Saved as \(name)")
                                .font(.appBody).foregroundStyle(Color.appSuccess)
                        }
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.appSuccess.opacity(0.05))
                    }
                }
            }
            .navigationTitle("PDF Metadata")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isProcessing { ProgressView() }
                    else if viewModel.didComplete { Button("Done") { dismiss() } }
                    else {
                        Button("Save") { save() }
                            .disabled(!canApply)
                    }
                }
            }
            .sheet(isPresented: $showPicker) {
                PDFFilePickerView(title: "Select PDF", allowsMultiple: false, selectedFiles: $selectedFiles)
            }
            .onChange(of: selectedFiles) { _, _ in
                guard let url = selectedFile?.fileURL else { return }
                if let meta = viewModel.readMetadata(url: url) {
                    title = meta.title
                    author = meta.author
                    subject = meta.subject
                    keywords = meta.keywords
                }
                if let file = selectedFile { outputName = "\(file.name) (updated)" }
            }
            .alert("Error", isPresented: $viewModel.showError) { Button("OK") {} } message: {
                Text(viewModel.errorMessage ?? "An error occurred.")
            }
            .confettiOnComplete(viewModel.didComplete)
        }
    }

    private var canApply: Bool {
        selectedFile != nil
            && !outputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        guard let url = selectedFile?.fileURL else { return }
        let metadata = PDFMetadata(title: title, author: author, subject: subject, keywords: keywords)
        viewModel.writeMetadata(url: url, metadata: metadata, outputName: outputName, context: modelContext)
    }
}
