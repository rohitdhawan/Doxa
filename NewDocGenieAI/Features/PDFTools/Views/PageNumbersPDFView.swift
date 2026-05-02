import SwiftUI
import SwiftData

struct PageNumbersPDFView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PDFToolsViewModel()
    @State private var selectedFiles: [DocumentFile] = []
    @State private var showPicker = false
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
                                VStack(alignment: .leading) {
                                    Text(file.fullFileName).font(.appBody).lineLimit(1)
                                    if let pages = file.pageCount {
                                        Text("\(pages) pages").font(.appCaption).foregroundStyle(Color.appTextDim)
                                    }
                                }
                            }
                        } else {
                            Label("Choose a PDF", systemImage: "doc.richtext").font(.appBody)
                        }
                    }
                }

                Section {
                    Text("Page numbers will be added at the bottom center of each page.")
                        .font(.appCaption).foregroundStyle(Color.appTextMuted)
                }

                Section("Output Name") {
                    TextField("Numbered document", text: $outputName)
                        .font(.appBody).autocorrectionDisabled()
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
            .navigationTitle("Page Numbers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isProcessing { ProgressView() }
                    else if viewModel.didComplete { Button("Done") { dismiss() } }
                    else {
                        Button("Add") { addNumbers() }
                            .disabled(selectedFile == nil || outputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .sheet(isPresented: $showPicker) {
                PDFFilePickerView(title: "Select PDF", allowsMultiple: false, selectedFiles: $selectedFiles)
            }
            .onChange(of: selectedFiles) { _, _ in
                if let file = selectedFile { outputName = "\(file.name) (numbered)" }
            }
            .alert("Error", isPresented: $viewModel.showError) { Button("OK") {} } message: {
                Text(viewModel.errorMessage ?? "An error occurred.")
            }
            .confettiOnComplete(viewModel.didComplete)
        }
    }

    private func addNumbers() {
        guard let url = selectedFile?.fileURL else { return }
        viewModel.addPageNumbers(url: url, outputName: outputName, context: modelContext)
    }
}
