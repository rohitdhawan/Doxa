import SwiftUI
import SwiftData

struct AskPDFView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AIDocumentViewModel()
    @State private var selectedFiles: [DocumentFile] = []
    @State private var showPicker = false
    @State private var questionText = ""

    private var selectedFile: DocumentFile? { selectedFiles.first }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.extractedDocumentText == nil && !viewModel.isProcessing {
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

                        if selectedFile != nil {
                            Section {
                                Button("Load Document") { loadDoc() }
                                    .font(.appBody)
                                    .foregroundStyle(Color.appPrimary)
                            }
                        }

                        Section {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: AIService.shared.isOnDeviceAIAvailable ? "checkmark.circle.fill" : "info.circle.fill")
                                    .foregroundStyle(AIService.shared.isOnDeviceAIAvailable ? Color.appSuccess : Color.appWarning)
                                Text(AIService.shared.isOnDeviceAIAvailable ? "AI-Powered Q&A" : "Keyword Search (AI unavailable)")
                                    .font(.appCaption).foregroundStyle(Color.appTextMuted)
                            }
                        }
                    }
                } else if viewModel.isProcessing && viewModel.extractedDocumentText == nil {
                    VStack(spacing: AppSpacing.lg) {
                        Spacer()
                        ProgressView().controlSize(.large)
                        Text("Loading document...").font(.appBody).foregroundStyle(Color.appTextMuted)
                        Spacer()
                    }
                } else {
                    chatArea
                    Divider().background(Color.appBorder)
                    inputBar
                }
            }
            .background(Color.appBGDark)
            .navigationTitle("Ask PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBGDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .sheet(isPresented: $showPicker) {
                PDFFilePickerView(title: "Select PDF", allowsMultiple: false, selectedFiles: $selectedFiles)
            }
            .alert("Error", isPresented: $viewModel.showError) { Button("OK") {} } message: {
                Text(viewModel.errorMessage ?? "An error occurred.")
            }
        }
    }

    private var chatArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(Array(viewModel.chatMessages.enumerated()), id: \.offset) { index, msg in
                        messageBubble(role: msg.role, content: msg.content)
                            .id(index)
                    }

                    if viewModel.isProcessing {
                        HStack {
                            TypingIndicator()
                            Spacer()
                        }
                        .id("typing")
                    }
                }
                .padding(AppSpacing.md)
            }
            .onChange(of: viewModel.chatMessages.count) { _, _ in
                withAnimation {
                    proxy.scrollTo(viewModel.chatMessages.count - 1, anchor: .bottom)
                }
            }
        }
    }

    private func messageBubble(role: String, content: String) -> some View {
        let isUser = role == "user"
        let bgColor: Color = isUser ? Color.appPrimary.opacity(0.2) : Color.appBGCard
        return HStack {
            if isUser { Spacer(minLength: 60) }
            Text(content)
                .font(.appBody)
                .foregroundStyle(Color.appText)
                .padding(AppSpacing.sm)
                .background(bgColor, in: RoundedRectangle(cornerRadius: AppCornerRadius.md))
            if !isUser { Spacer(minLength: 60) }
        }
    }

    private var inputBar: some View {
        HStack(spacing: AppSpacing.sm) {
            TextField("Ask a question...", text: $questionText)
                .font(.appBody)
                .padding(AppSpacing.sm)
                .background(Color.appBGCard, in: RoundedRectangle(cornerRadius: AppCornerRadius.md))
                .submitLabel(.send)
                .onSubmit { sendQuestion() }

            Button { sendQuestion() } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(canSend ? Color.appPrimary : Color.appTextDim)
            }
            .disabled(!canSend)
        }
        .padding(AppSpacing.md)
    }

    private var canSend: Bool {
        !questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isProcessing
    }

    private func loadDoc() {
        guard let url = selectedFile?.fileURL else { return }
        viewModel.loadDocument(url: url)
    }

    private func sendQuestion() {
        let q = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        questionText = ""
        viewModel.askQuestion(q)
    }
}
