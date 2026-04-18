import SwiftUI
import SwiftData
import PDFKit

struct SplitPDFView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PDFToolsViewModel()
    @State private var selectedFiles: [DocumentFile] = []
    @State private var showPicker = false
    @State private var startPage = ""
    @State private var endPage = ""
    @State private var outputName = ""
    @State private var totalPages = 0

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
                                Text(file.fullFileName)
                                    .font(.appBody)
                                    .lineLimit(1)
                            }
                        } else {
                            Label("Choose a PDF", systemImage: "doc.richtext")
                                .font(.appBody)
                        }
                    }

                    if totalPages > 0 {
                        Text("Total pages: \(totalPages)")
                            .font(.appCaption)
                            .foregroundStyle(Color.appTextMuted)
                    }
                }

                Section("Page Range") {
                    HStack {
                        TextField("Start", text: $startPage)
                            .keyboardType(.numberPad)
                            .font(.appBody)
                        Text("to")
                            .font(.appCaption)
                            .foregroundStyle(Color.appTextMuted)
                        TextField("End", text: $endPage)
                            .keyboardType(.numberPad)
                            .font(.appBody)
                    }
                }

                Section("Output Name") {
                    TextField("Split document", text: $outputName)
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
            .navigationTitle("Split PDF")
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
                        Button("Split") { split() }
                            .disabled(!canSplit)
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
                loadPageCount()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred.")
            }
            .confettiOnComplete(viewModel.didComplete)
        }
    }

    private var canSplit: Bool {
        selectedFile != nil
            && (Int(startPage) ?? 0) > 0
            && (Int(endPage) ?? 0) > 0
            && !outputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func loadPageCount() {
        guard let url = selectedFile?.fileURL,
              let doc = PDFDocument(url: url) else {
            totalPages = 0
            return
        }
        totalPages = doc.pageCount
        outputName = "\(selectedFile?.name ?? "Split") (pages)"
    }

    private func split() {
        guard let url = selectedFile?.fileURL,
              let start = Int(startPage),
              let end = Int(endPage) else { return }
        viewModel.splitPDF(url: url, startPage: start, endPage: end, outputName: outputName, context: modelContext)
    }
}
