import SwiftUI
import SwiftData

struct UnlockPDFView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PDFToolsViewModel()
    @State private var selectedFiles: [DocumentFile] = []
    @State private var showPicker = false
    @State private var password = ""
    @State private var outputName = ""

    private var selectedFile: DocumentFile? { selectedFiles.first }

    var body: some View {
        NavigationStack {
            Form {
                Section("Select Locked PDF") {
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
                            Label("Choose a PDF", systemImage: "lock.doc")
                                .font(.appBody)
                        }
                    }
                }

                Section("Password") {
                    SecureField("Enter PDF password", text: $password)
                        .font(.appBody)
                }

                Section("Output Name") {
                    TextField("Unlocked document", text: $outputName)
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
            .navigationTitle("Unlock PDF")
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
                        Button("Unlock") { unlock() }
                            .disabled(selectedFile == nil || password.isEmpty || outputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
                    outputName = "\(file.name) (unlocked)"
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

    private func unlock() {
        guard let url = selectedFile?.fileURL else { return }
        viewModel.unlockPDF(url: url, password: password, outputName: outputName, context: modelContext)
    }
}
