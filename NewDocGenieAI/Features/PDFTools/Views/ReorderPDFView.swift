import SwiftUI
import SwiftData
import PDFKit

struct ReorderPDFView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PDFToolsViewModel()
    @State private var selectedFiles: [DocumentFile] = []
    @State private var showPicker = false
    @State private var pageOrder: [Int] = []
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

                if !pageOrder.isEmpty {
                    Section("Page Order (drag to reorder)") {
                        ForEach(pageOrder, id: \.self) { pageNum in
                            HStack {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundStyle(Color.appTextDim)
                                Text("Page \(pageNum)")
                                    .font(.appBody).foregroundStyle(Color.appText)
                            }
                        }
                        .onMove { source, destination in
                            pageOrder.move(fromOffsets: source, toOffset: destination)
                        }
                    }
                }

                Section("Output Name") {
                    TextField("Reordered document", text: $outputName)
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
            .environment(\.editMode, .constant(pageOrder.isEmpty ? .inactive : .active))
            .navigationTitle("Reorder Pages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isProcessing { ProgressView() }
                    else if viewModel.didComplete { Button("Done") { dismiss() } }
                    else {
                        Button("Save") { reorder() }
                            .disabled(pageOrder.isEmpty || outputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .sheet(isPresented: $showPicker) {
                PDFFilePickerView(title: "Select PDF", allowsMultiple: false, selectedFiles: $selectedFiles)
            }
            .onChange(of: selectedFiles) { _, _ in loadPages() }
            .alert("Error", isPresented: $viewModel.showError) { Button("OK") {} } message: {
                Text(viewModel.errorMessage ?? "An error occurred.")
            }
            .confettiOnComplete(viewModel.didComplete)
        }
    }

    private func loadPages() {
        guard let url = selectedFile?.fileURL, let doc = PDFDocument(url: url) else {
            pageOrder = []; return
        }
        pageOrder = Array(1...doc.pageCount)
        outputName = "\(selectedFile?.name ?? "Reorder") (reordered)"
    }

    private func reorder() {
        guard let url = selectedFile?.fileURL else { return }
        viewModel.reorderPDF(url: url, newOrder: pageOrder, outputName: outputName, context: modelContext)
    }
}
