import SwiftUI
import SwiftData
import PDFKit

struct PDFViewerToolView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PDFViewerViewModel()
    @State private var selectedFiles: [DocumentFile] = []
    @State private var goToPageBinding: Int? = nil

    /// Optional initial PDF URL to load immediately (e.g. from "Open In" or file share)
    var initialURL: URL? = nil

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.hasDocument {
                    pdfContentView
                } else {
                    emptyPickerView
                }
            }
            .background(Color.appBackground)
            .navigationTitle(documentTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbar { toolbarContent }
            .sheet(isPresented: $viewModel.showFilePicker) {
                PDFFilePickerView(
                    title: "Select PDF",
                    allowsMultiple: false,
                    selectedFiles: $selectedFiles
                )
            }
            .sheet(isPresented: $viewModel.showThumbnails) {
                PDFThumbnailGridView(
                    thumbnails: viewModel.thumbnails,
                    currentPage: viewModel.currentPage,
                    onPageSelected: { page in
                        goToPageBinding = page
                        viewModel.goToPage(page)
                    }
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                if let url = viewModel.pdfURL {
                    ActivityView(activityItems: [url])
                }
            }
            .sheet(item: $viewModel.activeSubTool) { tool in
                toolSheet(for: tool)
                    .presentationCornerRadius(24)
                    .presentationBackground(.ultraThinMaterial)
            }
            .fullScreenCover(isPresented: $viewModel.showScanner) {
                DocumentCameraView(
                    onScanComplete: { images in
                        viewModel.scannedImages = images
                        viewModel.showScanner = false
                        if !images.isEmpty {
                            viewModel.showScanReview = true
                        }
                    },
                    onCancel: { viewModel.showScanner = false }
                )
                .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $viewModel.showScanReview) {
                ScanReviewView(scannedImages: viewModel.scannedImages)
            }
            .onChange(of: selectedFiles) { _, newFiles in
                if let file = newFiles.first, let url = file.fileURL {
                    viewModel.loadPDF(url: url)
                    selectedFiles = []
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred.")
            }
            .onAppear {
                if let url = initialURL, !viewModel.hasDocument {
                    // Start accessing security-scoped resource for files from other apps
                    let didAccess = url.startAccessingSecurityScopedResource()
                    viewModel.loadPDF(url: url)
                    if didAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
            }
        }
    }

    // MARK: - Document Title
    private var documentTitle: String {
        if let url = viewModel.pdfURL {
            return url.deletingPathExtension().lastPathComponent
        }
        return "PDF Viewer"
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading PDF...")
                .font(.appBody)
                .foregroundStyle(Color.appTextMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty Picker View
    private var emptyPickerView: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            VStack(spacing: AppSpacing.lg) {
                GlowingIcon(
                    systemName: "doc.richtext",
                    color: .appPrimary,
                    size: 48,
                    bgSize: 96
                )

                VStack(spacing: AppSpacing.sm) {
                    Text("PDF Viewer")
                        .font(.appH1)
                        .foregroundStyle(Color.appText)

                    Text("Select a PDF to view it with full controls\nincluding search, thumbnails, and more.")
                        .font(.appBody)
                        .foregroundStyle(Color.appTextMuted)
                        .multilineTextAlignment(.center)
                }
            }

            Button {
                HapticManager.medium()
                viewModel.showFilePicker = true
            } label: {
                Label("Choose PDF", systemImage: "folder")
                    .font(.appH3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(Color.appGradientPrimary, in: RoundedRectangle(cornerRadius: AppCornerRadius.lg))
            }
            .buttonStyle(.scale)
            .padding(.horizontal, AppSpacing.xl)

            // Quick actions grid
            VStack(spacing: AppSpacing.md) {
                Text("Or use a quick tool")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextDim)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.md), count: 3),
                    spacing: AppSpacing.md
                ) {
                    quickActionButton(icon: "doc.viewfinder", label: "Scan", color: .appAccent) {
                        viewModel.showScanner = true
                    }
                    quickActionButton(icon: "doc.on.doc.fill", label: "Merge", color: .appPrimary) {
                        viewModel.activeSubTool = .mergePDF
                    }
                    quickActionButton(icon: "arrow.down.doc", label: "Compress", color: .appSuccess) {
                        viewModel.activeSubTool = .compressPDF
                    }
                    quickActionButton(icon: "photo.on.rectangle", label: "IMG to PDF", color: .appWarning) {
                        viewModel.activeSubTool = .imageToPDF
                    }
                    quickActionButton(icon: "doc.text.fill", label: "Doc to PDF", color: .appPrimary) {
                        viewModel.activeSubTool = .docToPDF
                    }
                    quickActionButton(icon: "text.viewfinder", label: "OCR", color: .appSuccess) {
                        viewModel.activeSubTool = .ocrText
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }

            Spacer()
        }
    }

    // MARK: - Quick Action Button
    private func quickActionButton(
        icon: String,
        label: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: AppCornerRadius.md))

                Text(label)
                    .font(.appMicro)
                    .foregroundStyle(Color.appTextMuted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .glassCard()
        }
        .buttonStyle(.scale)
    }

    // MARK: - PDF Content View
    private var pdfContentView: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // Search bar (conditional)
                if viewModel.showSearch {
                    PDFSearchView(viewModel: viewModel)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // PDF view
                PDFKitView(
                    url: viewModel.pdfURL!,
                    currentPage: $viewModel.currentPage,
                    totalPages: $viewModel.totalPages,
                    goToPage: goToPageBinding,
                    highlightSelection: viewModel.currentSearchResult
                )
                .ignoresSafeArea(edges: .bottom)

                // Bottom toolbar
                bottomToolbar
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.showSearch)
    }

    // MARK: - Bottom Toolbar
    private var bottomToolbar: some View {
        HStack(spacing: 0) {
            // Page indicator
            if viewModel.totalPages > 0 {
                Text("Page \(viewModel.currentPage) of \(viewModel.totalPages)")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextMuted)
                    .frame(minWidth: 80)
            }

            Spacer()

            // Action buttons
            HStack(spacing: AppSpacing.lg) {
                toolbarButton(icon: "magnifyingglass", label: "Search") {
                    withAnimation { viewModel.showSearch.toggle() }
                }

                toolbarButton(icon: "square.grid.2x2", label: "Pages") {
                    viewModel.showThumbnails = true
                }

                toolbarButton(icon: "square.and.arrow.up", label: "Share") {
                    viewModel.showShareSheet = true
                }

                // More actions menu
                Menu {
                    Section("Scan & Create") {
                        Button {
                            viewModel.showScanner = true
                        } label: {
                            Label("Scan Document", systemImage: "doc.viewfinder")
                        }

                        Button {
                            viewModel.activeSubTool = .mergePDF
                        } label: {
                            Label("Merge PDFs", systemImage: "doc.on.doc.fill")
                        }
                    }

                    Section("Convert") {
                        Button {
                            viewModel.activeSubTool = .pdfToImage
                        } label: {
                            Label("Convert to Image", systemImage: "photo")
                        }

                        Button {
                            viewModel.activeSubTool = .pdfToText
                        } label: {
                            Label("Extract Text", systemImage: "doc.plaintext")
                        }

                        Button {
                            viewModel.activeSubTool = .ocrText
                        } label: {
                            Label("OCR Text", systemImage: "text.viewfinder")
                        }
                    }

                    Section("Edit") {
                        Button {
                            viewModel.activeSubTool = .compressPDF
                        } label: {
                            Label("Compress", systemImage: "arrow.down.doc")
                        }

                        Button {
                            viewModel.activeSubTool = .watermark
                        } label: {
                            Label("Add Watermark", systemImage: "drop.triangle")
                        }

                        Button {
                            viewModel.activeSubTool = .rotatePDF
                        } label: {
                            Label("Rotate Pages", systemImage: "rotate.right")
                        }

                        Button {
                            viewModel.activeSubTool = .cropPDF
                        } label: {
                            Label("Crop Pages", systemImage: "crop")
                        }

                        Button {
                            viewModel.activeSubTool = .signPDF
                        } label: {
                            Label("Sign PDF", systemImage: "signature")
                        }
                    }

                    Section("Security") {
                        Button {
                            viewModel.activeSubTool = .lockPDF
                        } label: {
                            Label("Lock PDF", systemImage: "lock.doc")
                        }

                        Button {
                            viewModel.activeSubTool = .unlockPDF
                        } label: {
                            Label("Unlock PDF", systemImage: "lock.open")
                        }
                    }

                    Section("Info") {
                        Button {
                            viewModel.activeSubTool = .metadataEditor
                        } label: {
                            Label("PDF Metadata", systemImage: "info.circle")
                        }
                    }

                    Section {
                        Button {
                            viewModel.activeSubTool = .emailPDF
                        } label: {
                            Label("Email PDF", systemImage: "envelope")
                        }

                        Button {
                            printPDF()
                        } label: {
                            Label("Print", systemImage: "printer")
                        }
                    }

                    Divider()

                    Button {
                        HapticManager.medium()
                        viewModel.showFilePicker = true
                    } label: {
                        Label("Open Another PDF", systemImage: "folder")
                    }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundStyle(Color.appPrimary)
                        Text("More")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.appTextMuted)
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider().foregroundStyle(Color.appBorder)
        }
    }

    // MARK: - Toolbar Button
    private func toolbarButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.selection()
            action()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.appPrimary)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(Color.appTextMuted)
            }
        }
    }

    // MARK: - Toolbar Content
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.appTextMuted)
            }
        }

        if viewModel.hasDocument {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    HapticManager.medium()
                    viewModel.showFilePicker = true
                } label: {
                    Image(systemName: "folder")
                        .foregroundStyle(Color.appPrimary)
                }
            }
        }
    }

    // MARK: - Print
    private func printPDF() {
        guard let url = viewModel.pdfURL,
              let data = try? Data(contentsOf: url) else { return }

        let printController = UIPrintInteractionController.shared
        printController.printingItem = data

        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = documentTitle
        printController.printInfo = printInfo

        printController.present(animated: true)
    }

    // MARK: - Tool Sheet
    @ViewBuilder
    private func toolSheet(for tool: ToolItem) -> some View {
        switch tool {
        case .mergePDF: MergePDFView()
        case .splitPDF: SplitPDFView()
        case .compressPDF: CompressPDFView()
        case .lockPDF: LockPDFView()
        case .unlockPDF: UnlockPDFView()
        case .extractPages: ExtractPagesPDFView()
        case .rotatePDF: RotatePDFView()
        case .reorderPDF: ReorderPDFView()
        case .pageNumbers: PageNumbersPDFView()
        case .watermark: WatermarkPDFView()
        case .ocrText: OCRTextView()
        case .imageToPDF: ImageToPDFView()
        case .docToPDF: DocToPDFView()
        case .pdfToImage: PDFToImageView()
        case .pdfToText: PDFToTextView()
        case .signPDF: SignPDFView()
        case .cropPDF: CropPDFView()
        case .metadataEditor: MetadataEditorView()
        case .summarizePDF: SummarizePDFView()
        case .askPDF: AskPDFView()
        case .translatePDF: TranslatePDFView()
        case .emailPDF: EmailPDFView()
        default: EmptyView()
        }
    }
}
