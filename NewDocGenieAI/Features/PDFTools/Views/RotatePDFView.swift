import SwiftUI
import SwiftData

struct RotatePDFView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PDFToolsViewModel()
    @State private var selectedFiles: [DocumentFile] = []
    @State private var showPicker = false
    @State private var rotationDegrees = 90
    @State private var outputName = ""

    private var selectedFile: DocumentFile? { selectedFiles.first }

    private let rotationOptions = [90, 180, 270]

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

                Section("Rotation") {
                    ForEach(rotationOptions, id: \.self) { degrees in
                        Button {
                            rotationDegrees = degrees
                        } label: {
                            HStack {
                                Text("\(degrees) degrees clockwise")
                                    .font(.appBody).foregroundStyle(Color.appText)
                                Spacer()
                                if rotationDegrees == degrees {
                                    Image(systemName: "checkmark").foregroundStyle(Color.appPrimary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Output Name") {
                    TextField("Rotated document", text: $outputName)
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
            .navigationTitle("Rotate PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isProcessing { ProgressView() }
                    else if viewModel.didComplete { Button("Done") { dismiss() } }
                    else {
                        Button("Rotate") { rotate() }
                            .disabled(selectedFile == nil || outputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .sheet(isPresented: $showPicker) {
                PDFFilePickerView(title: "Select PDF", allowsMultiple: false, selectedFiles: $selectedFiles)
            }
            .onChange(of: selectedFiles) { _, _ in
                if let file = selectedFile { outputName = "\(file.name) (rotated)" }
            }
            .alert("Error", isPresented: $viewModel.showError) { Button("OK") {} } message: {
                Text(viewModel.errorMessage ?? "An error occurred.")
            }
            .confettiOnComplete(viewModel.didComplete)
        }
    }

    private func rotate() {
        guard let url = selectedFile?.fileURL else { return }
        viewModel.rotatePDF(url: url, degrees: rotationDegrees, outputName: outputName, context: modelContext)
    }
}
