import SwiftUI
import SwiftData

struct CropPDFView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PDFToolsViewModel()
    @State private var selectedFiles: [DocumentFile] = []
    @State private var showPicker = false
    @State private var topMargin: Double = 0
    @State private var bottomMargin: Double = 0
    @State private var leftMargin: Double = 0
    @State private var rightMargin: Double = 0
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

                Section("Crop Margins (points)") {
                    sliderRow("Top", value: $topMargin)
                    sliderRow("Bottom", value: $bottomMargin)
                    sliderRow("Left", value: $leftMargin)
                    sliderRow("Right", value: $rightMargin)
                    Text("Adjust margins to crop from each edge of every page.")
                        .font(.appCaption).foregroundStyle(Color.appTextMuted)
                }

                Section("Output Name") {
                    TextField("Cropped document", text: $outputName)
                        .font(.appBody).autocorrectionDisabled()
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
            .navigationTitle("Crop PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBGDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isProcessing { ProgressView() }
                    else if viewModel.didComplete { Button("Done") { dismiss() } }
                    else {
                        Button("Apply") { crop() }
                            .disabled(!canApply)
                    }
                }
            }
            .sheet(isPresented: $showPicker) {
                PDFFilePickerView(title: "Select PDF", allowsMultiple: false, selectedFiles: $selectedFiles)
            }
            .onChange(of: selectedFiles) { _, _ in
                if let file = selectedFile { outputName = "\(file.name) (cropped)" }
            }
            .alert("Error", isPresented: $viewModel.showError) { Button("OK") {} } message: {
                Text(viewModel.errorMessage ?? "An error occurred.")
            }
            .confettiOnComplete(viewModel.didComplete)
        }
    }

    private var canApply: Bool {
        selectedFile != nil
            && (topMargin > 0 || bottomMargin > 0 || leftMargin > 0 || rightMargin > 0)
            && !outputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func crop() {
        guard let url = selectedFile?.fileURL else { return }
        viewModel.cropPDF(url: url, top: topMargin, bottom: bottomMargin, left: leftMargin, right: rightMargin, outputName: outputName, context: modelContext)
    }

    private func sliderRow(_ label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.appBody)
                Spacer()
                Text("\(Int(value.wrappedValue)) pt").font(.appCaption).foregroundStyle(Color.appTextMuted)
            }
            Slider(value: value, in: 0...200, step: 1)
                .tint(Color.appPrimary)
        }
    }
}
