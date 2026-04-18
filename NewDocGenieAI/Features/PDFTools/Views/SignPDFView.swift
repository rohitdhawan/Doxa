import SwiftUI
import SwiftData
import PencilKit
import PDFKit

struct SignPDFView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PDFToolsViewModel()
    @State private var selectedFiles: [DocumentFile] = []
    @State private var showPicker = false
    @State private var drawing = PKDrawing()
    @State private var selectedPage = 1
    @State private var signaturePosition = SignaturePosition.bottomRight
    @State private var outputName = ""

    private var selectedFile: DocumentFile? { selectedFiles.first }
    private var pageCount: Int {
        guard let url = selectedFile?.fileURL else { return 1 }
        return PDFDocument(url: url)?.pageCount ?? 1
    }

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

                Section("Draw Signature") {
                    SignatureCanvasView(drawing: $drawing)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
                    Button("Clear Signature") {
                        drawing = PKDrawing()
                    }
                    .font(.appCaption)
                    .foregroundStyle(Color.appDanger)
                }

                Section("Placement") {
                    if pageCount > 1 {
                        Stepper("Page \(selectedPage) of \(pageCount)", value: $selectedPage, in: 1...pageCount)
                            .font(.appBody)
                    }
                    Picker("Position", selection: $signaturePosition) {
                        ForEach(SignaturePosition.allCases) { pos in
                            Text(pos.label).tag(pos)
                        }
                    }
                    .font(.appBody)
                }

                Section("Output Name") {
                    TextField("Signed document", text: $outputName)
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
            .navigationTitle("Sign PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBGDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isProcessing { ProgressView() }
                    else if viewModel.didComplete { Button("Done") { dismiss() } }
                    else {
                        Button("Apply") { sign() }
                            .disabled(!canApply)
                    }
                }
            }
            .sheet(isPresented: $showPicker) {
                PDFFilePickerView(title: "Select PDF", allowsMultiple: false, selectedFiles: $selectedFiles)
            }
            .onChange(of: selectedFiles) { _, _ in
                if let file = selectedFile { outputName = "\(file.name) (signed)" }
            }
            .alert("Error", isPresented: $viewModel.showError) { Button("OK") {} } message: {
                Text(viewModel.errorMessage ?? "An error occurred.")
            }
            .confettiOnComplete(viewModel.didComplete)
        }
    }

    private var canApply: Bool {
        selectedFile != nil
            && !drawing.bounds.isEmpty
            && !outputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func sign() {
        guard let url = selectedFile?.fileURL else { return }
        let bounds = drawing.bounds
        let scale: CGFloat = 2.0
        let sigImage = drawing.image(from: bounds, scale: scale)
        viewModel.signPDF(
            url: url,
            signatureImage: sigImage,
            pageIndex: selectedPage - 1,
            position: signaturePosition.normalizedPosition,
            signatureSize: CGSize(width: 150, height: 75),
            outputName: outputName,
            context: modelContext
        )
    }
}

private enum SignaturePosition: String, CaseIterable, Identifiable {
    case bottomLeft, bottomCenter, bottomRight

    var id: String { rawValue }

    var label: String {
        switch self {
        case .bottomLeft: return "Bottom Left"
        case .bottomCenter: return "Bottom Center"
        case .bottomRight: return "Bottom Right"
        }
    }

    var normalizedPosition: CGPoint {
        switch self {
        case .bottomLeft: return CGPoint(x: 0.2, y: 0.9)
        case .bottomCenter: return CGPoint(x: 0.5, y: 0.9)
        case .bottomRight: return CGPoint(x: 0.8, y: 0.9)
        }
    }
}
