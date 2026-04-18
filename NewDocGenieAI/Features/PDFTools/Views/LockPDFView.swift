import SwiftUI
import SwiftData

struct LockPDFView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PDFToolsViewModel()
    @State private var selectedFiles: [DocumentFile] = []
    @State private var showPicker = false
    @State private var password = ""
    @State private var confirmPassword = ""
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
                                Text(file.fullFileName)
                                    .font(.appBody)
                                    .lineLimit(1)
                            }
                        } else {
                            Label("Choose a PDF", systemImage: "doc.richtext")
                                .font(.appBody)
                        }
                    }
                }

                Section("Password") {
                    SecureField("Enter password", text: $password)
                        .font(.appBody)
                    SecureField("Confirm password", text: $confirmPassword)
                        .font(.appBody)

                    if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
                        Text("Passwords do not match")
                            .font(.appCaption)
                            .foregroundStyle(Color.appDanger)
                    }
                }

                Section("Output Name") {
                    TextField("Locked document", text: $outputName)
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
            .navigationTitle("Lock PDF")
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
                        Button("Lock") { lock() }
                            .disabled(!canLock)
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
                    outputName = "\(file.name) (locked)"
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

    private var canLock: Bool {
        selectedFile != nil
            && !password.isEmpty
            && password == confirmPassword
            && !outputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func lock() {
        guard let url = selectedFile?.fileURL else { return }
        viewModel.lockPDF(url: url, password: password, outputName: outputName, context: modelContext)
    }
}
