import SwiftUI
import SwiftData
import TipKit
import PhotosUI

struct ChatTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationRouter.self) private var router
    @Query(sort: \ChatMessage.timestamp) private var allMessages: [ChatMessage]
    @Query(sort: \Conversation.updatedAt, order: .reverse) private var conversations: [Conversation]
    @Query(sort: \DocumentFile.importedAt) private var allDocuments: [DocumentFile]
    @State private var viewModel = ChatViewModel()
    @State private var coordinator = ChatToolCoordinator()
    @State private var showHistory = false
    @State private var speechService = SpeechRecognitionService()
    @State private var showAttachmentMenu = false
    @State private var showDocumentPicker = false
    @State private var showPhotoPicker = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showVoiceError = false
    @State private var voiceErrorMessage = ""
    @FocusState private var isInputFocused: Bool

    private var messages: [ChatMessage] {
        viewModel.messagesForCurrentConversation(allMessages: allMessages)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if messages.isEmpty && !viewModel.isTyping {
                    welcomeView
                } else {
                    messageList
                }

                if viewModel.isTyping && viewModel.streamingContent.isEmpty {
                    HStack(spacing: AppSpacing.sm) {
                        TypingIndicator()
                        Spacer()
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.xs)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                QuickActionsView(actions: viewModel.actions) { action in
                    if let toolId = action.toolId, let tool = coordinator.toolForId(toolId) {
                        coordinator.openTool(tool)
                    } else {
                        viewModel.sendQuickAction(action, context: modelContext)
                    }
                }
                .padding(.vertical, AppSpacing.xs)

                Divider().background(Color.appBorder)

                ChatInputBar(
                    text: $viewModel.inputText,
                    isInputFocused: $isInputFocused,
                    isTyping: viewModel.isTyping,
                    pendingAttachment: viewModel.pendingAttachment,
                    isRecording: speechService.isRecording,
                    audioLevel: speechService.audioLevel,
                    onSend: {
                        isInputFocused = false
                        viewModel.sendMessage(context: modelContext, allMessages: allMessages)
                    },
                    onAttachTapped: {
                        isInputFocused = false
                        showAttachmentMenu = true
                    },
                    onVoiceToggle: {
                        isInputFocused = false
                        handleVoiceToggle()
                    },
                    onRemoveAttachment: { viewModel.removeAttachment() }
                )
            }
            .background(Color.appBGDark)
            .contentShape(Rectangle())
            .onTapGesture {
                isInputFocused = false
            }
            .navigationTitle("Doxa")
            .toolbarBackground(Color.appBGDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticManager.light()
                        viewModel.currentConversation = nil
                    } label: {
                        Image(systemName: "house.fill")
                            .foregroundStyle(Color.appPrimary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.light()
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(Color.appPrimary)
                    }
                }
            }
            .sheet(isPresented: $showHistory) {
                ChatHistoryView(
                    conversations: conversations,
                    onSelect: { conversation in
                        viewModel.currentConversation = conversation
                        showHistory = false
                    },
                    onDelete: { conversation in
                        deleteConversation(conversation)
                    }
                )
                .presentationCornerRadius(24)
                .presentationBackground(.ultraThinMaterial)
            }
            .sheet(item: $coordinator.activeTool) { tool in
                toolSheet(for: tool)
                    .presentationCornerRadius(24)
                    .presentationBackground(.ultraThinMaterial)
            }
            .fullScreenCover(isPresented: $coordinator.showScanner) {
                DocumentCameraView(
                    onScanComplete: { images in
                        coordinator.showScanner = false
                        // Delay processing until fullScreenCover dismissal completes
                        if !images.isEmpty {
                            let captured = images
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                viewModel.handleScannedImages(captured, context: modelContext)
                            }
                        }
                    },
                    onCancel: { coordinator.showScanner = false }
                )
                .ignoresSafeArea()
            }
            .confirmationDialog("Attach", isPresented: $showAttachmentMenu, titleVisibility: .hidden) {
                Button {
                    // Delay camera launch until confirmationDialog finishes dismissing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        coordinator.showScanner = true
                    }
                } label: {
                    Label("Camera Scan", systemImage: "doc.viewfinder")
                }
                Button {
                    showDocumentPicker = true
                } label: {
                    Label("Browse Files", systemImage: "folder")
                }
                Button {
                    showPhotoPicker = true
                } label: {
                    Label("Photo Library", systemImage: "photo.on.rectangle")
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPickerView(
                    allowsMultipleSelection: false,
                    onPick: { urls in
                        if let url = urls.first {
                            viewModel.attachFile(url: url)
                        }
                    }
                )
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotos, maxSelectionCount: 1, matching: .images)
            .onChange(of: selectedPhotos) { _, newValue in
                handlePhotoSelection(newValue)
            }
            .alert("Voice Input", isPresented: $showVoiceError) {
                Button("OK") {}
            } message: {
                Text(voiceErrorMessage)
            }
            .onChange(of: speechService.transcribedText) { _, newValue in
                if !newValue.isEmpty {
                    viewModel.inputText = newValue
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .toolDidProduceDocument)) { notification in
                guard let userInfo = notification.userInfo,
                      let documentId = userInfo["documentId"] as? String,
                      let toolName = userInfo["toolName"] as? String else { return }
                viewModel.handleToolOutput(documentId: documentId, toolName: toolName, context: modelContext)
            }
        }
    }

    // MARK: - Welcome View
    private var welcomeView: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                Spacer(minLength: AppSpacing.xl)

                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.appGradientPrimary)
                    .symbolEffect(.pulse, options: .repeating)
                    .popoverTip(ChatWelcomeTip())

                Text("Doxa")
                    .font(.appH1)
                    .overlay {
                        AnimatedGradientView(colors: [.appPrimary, .appAccent, .appPrimary])
                    }
                    .mask {
                        Text("Doxa")
                            .font(.appH1)
                    }

                Text("Your AI document assistant")
                    .font(.appBody)
                    .foregroundStyle(Color.appTextMuted)

                if AIService.shared.isOnDeviceAIAvailable {
                    Label("On-Device AI", systemImage: "apple.intelligence")
                        .font(.appCaption)
                        .foregroundStyle(Color.appSuccess)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(Color.appSuccess.opacity(0.15), in: Capsule())
                }

                Spacer(minLength: AppSpacing.md)

                // Feature suggestion cards
                VStack(spacing: AppSpacing.sm) {
                    ForEach(Array(viewModel.actions.enumerated()), id: \.element.id) { index, action in
                        WelcomeSuggestionCard(action: action) {
                            HapticManager.light()
                            if let toolId = action.toolId, let tool = coordinator.toolForId(toolId) {
                                coordinator.openTool(tool)
                            } else {
                                viewModel.sendQuickAction(action, context: modelContext)
                            }
                        }
                        .staggeredAppear(index: index)
                    }
                }
                .padding(.horizontal, AppSpacing.sm)

                Spacer(minLength: AppSpacing.lg)
            }
            .padding(AppSpacing.md)
        }
        .background(
            AnimatedGradientView(colors: [.appPrimary.opacity(0.05), .appAccent.opacity(0.05), .appPrimary.opacity(0.05)])
                .ignoresSafeArea()
        )
        .task {
            await ChatWelcomeTip.chatTabVisited.donate()
        }
    }

    // MARK: - Message List
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                        if shouldShowTimestamp(for: index) {
                            Text(message.timestamp.formatted(.dateTime.hour().minute()))
                                .font(.appMicro)
                                .foregroundStyle(Color.appTextDim)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, AppSpacing.xs)
                        }

                        ChatBubbleView(message: message) { action in
                            viewModel.handleAction(action, coordinator: coordinator, router: router, context: modelContext)
                        }
                        .id(message.id)
                        .staggeredAppear(index: index)
                    }
                }
                .padding(AppSpacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
            .simultaneousGesture(
                DragGesture().onChanged { _ in
                    isInputFocused = false
                }
            )
            .onChange(of: messages.count) { _, _ in
                if let lastMessage = messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.streamingContent) { _, _ in
                if let lastMessage = messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Tool Sheets
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
        case .pdfViewer: PDFViewerToolView()
        case .scanner: EmptyView()
        }
    }

    private func shouldShowTimestamp(for index: Int) -> Bool {
        guard index > 0 else { return true }
        let current = messages[index].timestamp
        let previous = messages[index - 1].timestamp
        return current.timeIntervalSince(previous) > 300
    }

    private func deleteConversation(_ conversation: Conversation) {
        let conversationId = conversation.id
        let messagesToDelete = allMessages.filter { $0.conversationId == conversationId }
        for msg in messagesToDelete {
            modelContext.delete(msg)
        }
        modelContext.delete(conversation)
        try? modelContext.save()

        if viewModel.currentConversation?.id == conversationId {
            viewModel.currentConversation = nil
        }
    }

    // MARK: - Voice Input

    private func handleVoiceToggle() {
        #if targetEnvironment(simulator)
        voiceErrorMessage = "Voice input is not available in the Simulator. Please use a physical device."
        showVoiceError = true
        return
        #else
        Task { @MainActor in
            await speechService.toggleRecording()

            if let message = speechService.errorMessage {
                voiceErrorMessage = message
                showVoiceError = true
            }
        }
        #endif
    }

    // MARK: - Photo Selection

    private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        guard let item = items.first else { return }
        selectedPhotos = []

        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else { return }

            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "photo_\(UUID().uuidString).jpg"
            let tempURL = tempDir.appendingPathComponent(fileName)

            do {
                try data.write(to: tempURL)
                await MainActor.run {
                    viewModel.attachFile(url: tempURL)
                }
            } catch {
                // Silently fail — user can retry
            }
        }
    }
}
