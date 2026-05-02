import SwiftUI
import SwiftData
import PDFKit

struct ExtractPagesPDFView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PDFToolsViewModel()
    @State private var selectedFiles: [DocumentFile] = []
    @State private var showPicker = false
    @State private var pagesInput = ""
    @State private var outputName = ""
    @State private var totalPages = 0

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
                    if totalPages > 0 {
                        Text("Total pages: \(totalPages)")
                            .font(.appCaption).foregroundStyle(Color.appTextMuted)
                    }
                }

                Section("Pages to Extract") {
                    TextField("e.g. 1, 3, 5-8", text: $pagesInput)
                        .font(.appBody).keyboardType(.numbersAndPunctuation)
                    Text("Enter page numbers separated by commas. Use dashes for ranges.")
                        .font(.appCaption).foregroundStyle(Color.appTextMuted)
                }

                Section("Output Name") {
                    TextField("Extracted pages", text: $outputName)
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
            .navigationTitle("Extract Pages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isProcessing { ProgressView() }
                    else if viewModel.didComplete { Button("Done") { dismiss() } }
                    else {
                        Button("Extract") { extract() }
                            .disabled(selectedFile == nil || pagesInput.isEmpty || outputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .sheet(isPresented: $showPicker) {
                PDFFilePickerView(title: "Select PDF", allowsMultiple: false, selectedFiles: $selectedFiles)
            }
            .onChange(of: selectedFiles) { _, _ in loadPageCount() }
            .alert("Error", isPresented: $viewModel.showError) { Button("OK") {} } message: {
                Text(viewModel.errorMessage ?? "An error occurred.")
            }
            .confettiOnComplete(viewModel.didComplete)
        }
    }

    private func loadPageCount() {
        guard let url = selectedFile?.fileURL, let doc = PDFDocument(url: url) else { totalPages = 0; return }
        totalPages = doc.pageCount
        outputName = "\(selectedFile?.name ?? "Extract") (pages)"
    }

    private func extract() {
        guard let url = selectedFile?.fileURL else { return }
        let indices = parsePageIndices(pagesInput)
        guard !indices.isEmpty else { return }
        viewModel.extractPages(url: url, pageIndices: indices, outputName: outputName, context: modelContext)
    }

    private func parsePageIndices(_ input: String) -> [Int] {
        var result: [Int] = []
        let parts = input.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        for part in parts {
            if part.contains("-") {
                let range = part.components(separatedBy: "-").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                if range.count == 2, range[0] <= range[1] {
                    result.append(contentsOf: range[0]...range[1])
                }
            } else if let num = Int(part) {
                result.append(num)
            }
        }
        return result
    }
}
