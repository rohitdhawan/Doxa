import SwiftUI
import SwiftData

struct PDFToImageView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ConverterViewModel()
    @State private var selectedFiles: [DocumentFile] = []
    @State private var showPicker = false
    @State private var imageFormat: ConverterService.ImageFormat = .jpg

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

                Section("Image Format") {
                    ForEach(ConverterService.ImageFormat.allCases) { format in
                        Button {
                            imageFormat = format
                        } label: {
                            HStack {
                                Text(format.rawValue).font(.appBody).foregroundStyle(Color.appText)
                                Spacer()
                                if imageFormat == format {
                                    Image(systemName: "checkmark").foregroundStyle(Color.appPrimary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section {
                    Text("Each page will be exported as a separate image file.")
                        .font(.appCaption).foregroundStyle(Color.appTextMuted)
                }

                if viewModel.didComplete, let name = viewModel.resultFileName {
                    Section {
                        VStack(spacing: AppSpacing.sm) {
                            AnimatedCheckmark()
                            Text(name)
                                .font(.appBody)
                                .foregroundStyle(Color.appSuccess)
                        }
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.appSuccess.opacity(0.05))
                    }
                }
            }
            .navigationTitle("PDF to Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isProcessing { ProgressView() }
                    else if viewModel.didComplete { Button("Done") { dismiss() } }
                    else {
                        Button("Export") { export() }
                            .disabled(selectedFile == nil)
                    }
                }
            }
            .sheet(isPresented: $showPicker) {
                PDFFilePickerView(title: "Select PDF", allowsMultiple: false, selectedFiles: $selectedFiles)
            }
            .alert("Error", isPresented: $viewModel.showError) { Button("OK") {} } message: {
                Text(viewModel.errorMessage ?? "An error occurred.")
            }
            .confettiOnComplete(viewModel.didComplete)
        }
    }

    private func export() {
        guard let url = selectedFile?.fileURL else { return }
        viewModel.pdfToImages(url: url, format: imageFormat, context: modelContext)
    }
}
