import SwiftUI
import SwiftData

struct TranslatePDFView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AIDocumentViewModel()
    @State private var selectedFiles: [DocumentFile] = []
    @State private var showPicker = false
    @State private var targetLanguage = "Spanish"
    @State private var outputName = ""

    private var selectedFile: DocumentFile? { selectedFiles.first }

    private let languages = [
        "Spanish", "French", "German", "Chinese", "Japanese",
        "Korean", "Portuguese", "Italian", "Russian", "Arabic", "Hindi"
    ]

    var body: some View {
        NavigationStack {
            Group {
                if let text = viewModel.resultText {
                    resultView(text)
                } else if viewModel.isProcessing {
                    VStack(spacing: AppSpacing.lg) {
                        Spacer()
                        ProgressView().controlSize(.large)
                        Text("Translating to \(targetLanguage)...")
                            .font(.appBody).foregroundStyle(Color.appTextMuted)
                        Spacer()
                    }
                } else {
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

                        Section("Target Language") {
                            Picker("Language", selection: $targetLanguage) {
                                ForEach(languages, id: \.self) { lang in
                                    Text(lang).tag(lang)
                                }
                            }
                            .font(.appBody)
                        }

                        if !AIService.shared.isOnDeviceAIAvailable {
                            Section {
                                Label("Requires iOS 26+", systemImage: "exclamationmark.triangle")
                                    .foregroundStyle(Color.appWarning)
                                    .font(.appBody)
                                Text("On-device AI is needed for translation.")
                                    .font(.appCaption).foregroundStyle(Color.appTextMuted)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Translate PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBGDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.resultText != nil {
                        Button("Done") { dismiss() }
                    } else if !viewModel.isProcessing {
                        Button("Translate") { translate() }
                            .disabled(selectedFile == nil || !AIService.shared.isOnDeviceAIAvailable)
                    }
                }
            }
            .sheet(isPresented: $showPicker) {
                PDFFilePickerView(title: "Select PDF", allowsMultiple: false, selectedFiles: $selectedFiles)
            }
            .onChange(of: selectedFiles) { _, _ in
                if let file = selectedFile { outputName = "\(file.name) (\(targetLanguage))" }
            }
            .alert("Error", isPresented: $viewModel.showError) { Button("OK") {} } message: {
                Text(viewModel.errorMessage ?? "An error occurred.")
            }
            .confettiOnComplete(viewModel.didComplete)
        }
    }

    private func resultView(_ text: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Save as...", text: $outputName)
                    .font(.appBody).autocorrectionDisabled()
                Button("Save as TXT") {
                    viewModel.saveResultAsText(outputName: outputName, context: modelContext)
                }
                .font(.appCaption)
                .disabled(outputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button { UIPasteboard.general.string = text; HapticManager.light() } label: {
                    Image(systemName: "doc.on.doc")
                }
            }
            .padding(AppSpacing.md)

            Divider()

            ScrollView {
                Text(text)
                    .font(.appBody)
                    .foregroundStyle(Color.appText)
                    .textSelection(.enabled)
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func translate() {
        guard let url = selectedFile?.fileURL else { return }
        viewModel.translatePDF(url: url, targetLanguage: targetLanguage)
    }
}
