import SwiftUI
import SwiftData

struct MergePDFView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PDFToolsViewModel()
    @State private var selectedFiles: [DocumentFile] = []
    @State private var showPicker = false
    @State private var outputName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Select PDFs to Merge") {
                    Button {
                        showPicker = true
                    } label: {
                        Label(
                            selectedFiles.isEmpty ? "Choose PDFs" : "\(selectedFiles.count) PDFs selected",
                            systemImage: "doc.on.doc"
                        )
                        .font(.appBody)
                    }

                    ForEach(selectedFiles) { file in
                        HStack {
                            FileTypeIcon(fileExtension: "pdf")
                            Text(file.fullFileName)
                                .font(.appBody)
                                .lineLimit(1)
                        }
                    }
                    .onMove { source, destination in
                        selectedFiles.move(fromOffsets: source, toOffset: destination)
                    }
                }

                Section("Output Name") {
                    TextField("Merged document", text: $outputName)
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
            .navigationTitle("Merge PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
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
                        Button("Merge") { merge() }
                            .disabled(selectedFiles.count < 2 || outputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .sheet(isPresented: $showPicker) {
                PDFFilePickerView(
                    title: "Select PDFs",
                    allowsMultiple: true,
                    selectedFiles: $selectedFiles
                )
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred.")
            }
            .confettiOnComplete(viewModel.didComplete)
        }
    }

    private func merge() {
        let urls = selectedFiles.compactMap { $0.fileURL }
        guard urls.count >= 2 else { return }
        viewModel.mergePDFs(urls: urls, outputName: outputName, context: modelContext)
    }
}
