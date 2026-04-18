import SwiftUI
import SwiftData
import UIKit

@MainActor
@Observable
final class ChatViewModel {
    var inputText = ""
    var isTyping = false
    var streamingContent: String = ""
    var currentConversation: Conversation?
    var pendingAttachment: PendingAttachment?

    private let aiService = AIService.shared
    private var documentOCRContext: [String: String] = [:]

    private let quickActions: [QuickAction] = [
        QuickAction(label: "PDF Viewer", icon: "doc.richtext", prompt: "View & manage PDFs", toolId: "PDF Viewer"),
        QuickAction(label: "Scan", icon: "doc.viewfinder", prompt: "Scan a document", toolId: "Scanner"),
        QuickAction(label: "Merge", icon: "doc.on.doc.fill", prompt: "Merge my PDFs", toolId: "Merge PDF"),
        QuickAction(label: "Convert", icon: "arrow.triangle.2.circlepath", prompt: "Convert a file to PDF", toolId: nil),
        QuickAction(label: "OCR", icon: "text.viewfinder", prompt: "Extract text from an image", toolId: "OCR Text"),
        QuickAction(label: "Compress", icon: "arrow.down.doc", prompt: "Compress a PDF", toolId: "Compress"),
        QuickAction(label: "Watermark", icon: "drop.triangle", prompt: "Add a watermark to PDF", toolId: "Watermark"),
    ]

    var actions: [QuickAction] { quickActions }

    func attachFile(url: URL) {
        pendingAttachment = PendingAttachment.from(url: url)
    }

    func removeAttachment() {
        pendingAttachment = nil
    }

    func startNewConversation(context: ModelContext) {
        let conversation = Conversation()
        context.insert(conversation)
        try? context.save()
        currentConversation = conversation
        aiService.resetSession()
    }

    func sendMessage(context: ModelContext, allMessages: [ChatMessage] = []) {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let attachment = pendingAttachment

        guard !text.isEmpty || attachment != nil else { return }

        if currentConversation == nil {
            startNewConversation(context: context)
        }

        guard let conversation = currentConversation else { return }

        // Handle file attachment flow
        if let attachment {
            pendingAttachment = nil
            inputText = ""

            let userContent = text.isEmpty ? "Here's a file: \(attachment.fullFileName)" : text
            let userMessage = ChatMessage(
                content: userContent,
                role: "user",
                conversationId: conversation.id
            )
            context.insert(userMessage)

            conversation.updatedAt = .now
            if conversation.title == "New Chat" {
                conversation.title = String(userContent.prefix(40))
            }

            let importService = FileImportService()
            do {
                let imported = try importService.importFiles(from: [attachment.url], into: context)
                if let docFile = imported.first {
                    handleAttachedDocument(documentId: docFile.id.uuidString, document: docFile, context: context)
                }
            } catch {
                let errorMsg = ChatMessage(
                    content: "Failed to import the file. Please try again.",
                    role: "assistant",
                    conversationId: conversation.id
                )
                context.insert(errorMsg)
                try? context.save()
            }
            return
        }

        let userMessage = ChatMessage(
            content: text,
            role: "user",
            conversationId: conversation.id
        )
        context.insert(userMessage)

        conversation.updatedAt = .now
        if conversation.title == "New Chat" {
            conversation.title = String(text.prefix(40))
        }

        inputText = ""
        try? context.save()

        let convId = conversation.id
        let history = messagesForCurrentConversation(allMessages: allMessages)

        // Build enriched input with document OCR context if available
        var enrichedInput = text
        if !documentOCRContext.isEmpty {
            let conversationMessages = messagesForCurrentConversation(allMessages: allMessages)
            if let recentDocCard = conversationMessages.last(where: { $0.messageType == "documentCard" && !$0.documentFileId.isEmpty }),
               let ocrText = documentOCRContext[recentDocCard.documentFileId] {
                let truncatedOCR = String(ocrText.prefix(2000))
                enrichedInput = """
                [Document context from scanned/attached file]
                The following is text extracted from the user's document. Answer their question directly from this text. If they mention a language name, they want translation — do NOT suggest file conversion. If they ask about amounts or details, find them in the text.
                ---
                \(truncatedOCR)
                ---

                User question: \(text)
                """
            }
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.isTyping = true
            self.streamingContent = ""

            // Insert placeholder message for streaming
            nonisolated(unsafe) let placeholder = ChatMessage(
                content: "",
                role: "assistant",
                conversationId: convId
            )
            context.insert(placeholder)
            try? context.save()

            do {
                let result: AIResponse
                if self.aiService.supportsStreaming {
                    result = try await self.aiService.streamResponse(
                        for: enrichedInput,
                        conversationHistory: history
                    ) { [weak self] partialText in
                        self?.streamingContent = partialText
                        placeholder.content = partialText
                    }
                } else {
                    result = try await self.aiService.generateResponse(
                        for: enrichedInput,
                        conversationHistory: history
                    )
                }

                // Finalize the message
                placeholder.content = result.text
                placeholder.toolBadge = result.toolBadge
                if !result.actions.isEmpty,
                   let data = try? JSONEncoder().encode(result.actions) {
                    placeholder.actionsJSON = String(data: data, encoding: .utf8)
                }
                try? context.save()
            } catch {
                placeholder.content = "Sorry, I encountered an error. Try asking me about scanning, merging, or converting documents."
                try? context.save()
            }

            self.streamingContent = ""
            self.isTyping = false
        }
    }

    func sendQuickAction(_ action: QuickAction, context: ModelContext) {
        inputText = action.prompt
        sendMessage(context: context)
    }

    func handleAction(_ action: ChatAction, coordinator: ChatToolCoordinator, router: NavigationRouter, context: ModelContext) {
        switch action.actionType {
        case .openTool:
            if let toolId = action.toolId, let tool = coordinator.toolForId(toolId) {
                coordinator.openTool(tool)
            }
        case .navigateTab:
            if let tabId = action.tabId {
                switch tabId {
                case "tools": router.selectedTab = .tools
                case "files": router.selectedTab = .files
                default: break
                }
            }
        case .openFile:
            router.selectedTab = .files
        case .showResult:
            break
        case .executeInline:
            if let toolType = action.payload, let fileId = action.fileId {
                executeInlineAction(toolType: toolType, documentFileId: fileId, context: context)
            }
        case .copyText:
            if let text = action.payload {
                UIPasteboard.general.string = text
            }
        case .shareFile:
            router.selectedTab = .files
        }
    }

    func messagesForCurrentConversation(allMessages: [ChatMessage]) -> [ChatMessage] {
        guard let conversation = currentConversation else { return [] }
        return allMessages
            .filter { $0.conversationId == conversation.id }
            .sorted { $0.timestamp < $1.timestamp }
    }

    // MARK: - File Attachment

    func handleAttachedDocument(documentId: String, document: DocumentFile, context: ModelContext) {
        guard let conversation = currentConversation else { return }

        let actions = [
            ChatAction(label: "Extract Text", icon: "text.viewfinder", actionType: .executeInline, fileId: documentId, payload: "ocr"),
            ChatAction(label: "Summarize", icon: "doc.text.magnifyingglass", actionType: .executeInline, fileId: documentId, payload: "summarize"),
            ChatAction(label: "Compress PDF", icon: "arrow.down.doc", actionType: .executeInline, fileId: documentId, payload: "compress"),
            ChatAction(label: "Add Watermark", icon: "drop.triangle", actionType: .executeInline, fileId: documentId, payload: "watermark"),
            ChatAction(label: "Share", icon: "square.and.arrow.up", actionType: .shareFile, fileId: documentId),
        ]

        let cardMessage = ChatMessage(
            content: "I received \(document.fullFileName). What would you like to do with it?",
            role: "assistant",
            conversationId: conversation.id,
            toolBadge: "File Import",
            actions: actions,
            messageType: "documentCard",
            documentFileId: documentId
        )
        context.insert(cardMessage)
        try? context.save()

        // Background OCR → auto-summary for attached files too
        if let fileURL = document.fileURL {
            let cardMessageId = cardMessage.id
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.runBackgroundOCR(
                    documentId: documentId,
                    cardMessageId: cardMessageId,
                    fileURL: fileURL,
                    context: context
                )
            }
        }
    }

    // MARK: - Inline Scan-to-Chat

    private let inlineToolExecutor = InlineChatToolExecutor.shared

    func handleScannedImages(_ images: [UIImage], context: ModelContext) {
        guard !images.isEmpty else { return }

        HapticManager.success()

        if currentConversation == nil {
            let autoName = "Scan \(Date.now.formatted(.dateTime.month(.abbreviated).day().hour().minute()))"
            let conversation = Conversation(title: autoName)
            context.insert(conversation)
            do {
                try context.save()
            } catch {
                // If save fails, try to continue — SwiftData may auto-save
            }
            currentConversation = conversation
            aiService.resetSession()
        }

        guard let conversation = currentConversation else { return }

        let pages = images.map { ScannedPage(image: $0) }
        let autoFileName = "Scan \(Date.now.formatted(.dateTime.month(.abbreviated).day().hour().minute()))"

        do {
            let result = try ScannerService.shared.saveScanAsPDF(pages: pages, fileName: autoFileName)
            let metadata = FileMetadataService.shared.extractMetadata(from: result.url)

            let docFile = DocumentFile(
                name: (result.url.lastPathComponent as NSString).deletingPathExtension,
                fileExtension: "pdf",
                relativeFilePath: result.relativePath,
                fileSize: metadata.fileSize,
                pageCount: pages.count
            )
            context.insert(docFile)
            try context.save()

            let documentId = docFile.id.uuidString

            // Immediate document card with basic actions
            let basicActions = [
                ChatAction(label: "Extract Text", icon: "text.viewfinder", actionType: .executeInline, fileId: documentId, payload: "ocr"),
                ChatAction(label: "Summarize", icon: "doc.text.magnifyingglass", actionType: .executeInline, fileId: documentId, payload: "summarize"),
                ChatAction(label: "Compress PDF", icon: "arrow.down.doc", actionType: .executeInline, fileId: documentId, payload: "compress"),
                ChatAction(label: "Share", icon: "square.and.arrow.up", actionType: .shareFile, fileId: documentId),
            ]

            let pageLabel = pages.count == 1 ? "page" : "pages"
            let cardMessage = ChatMessage(
                content: "\(pages.count) \(pageLabel) scanned and saved as \(docFile.fullFileName)",
                role: "assistant",
                conversationId: conversation.id,
                toolBadge: "Scanner",
                actions: basicActions,
                messageType: "documentCard",
                documentFileId: documentId
            )
            context.insert(cardMessage)
            do {
                try context.save()
            } catch {
                // SwiftData may auto-save; continue
            }

            // Background OCR for smart action suggestions
            let cardMessageId = cardMessage.id
            let fileURL = result.url
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.runBackgroundOCR(
                    documentId: documentId,
                    cardMessageId: cardMessageId,
                    fileURL: fileURL,
                    context: context
                )
            }

        } catch {
            let errorMsg = ChatMessage(
                content: "Failed to save scanned document. Please try again.",
                role: "assistant",
                conversationId: conversation.id
            )
            context.insert(errorMsg)
            try? context.save()
            HapticManager.error()
        }
    }

    private func runBackgroundOCR(
        documentId: String,
        cardMessageId: UUID,
        fileURL: URL,
        context: ModelContext
    ) async {
        guard let conversation = currentConversation else { return }

        do {
            let ocrText = try await OCRService.shared.extractText(from: fileURL)

            // Store for AI follow-up questions
            documentOCRContext[documentId] = ocrText

            // Classify content
            let contentType = ScanContentType.classify(ocrText: ocrText)

            // Build smart actions
            var smartActions: [ChatAction] = contentType.suggestedActions.map { suggestion in
                ChatAction(
                    label: suggestion.label,
                    icon: suggestion.icon,
                    actionType: .executeInline,
                    fileId: documentId,
                    payload: suggestion.toolType
                )
            }
            smartActions.append(
                ChatAction(label: "Share", icon: "square.and.arrow.up", actionType: .shareFile, fileId: documentId)
            )

            // Update card message actions in-place
            let descriptor = FetchDescriptor<ChatMessage>()
            let allMsgs = (try? context.fetch(descriptor)) ?? []
            if let cardMsg = allMsgs.first(where: { $0.id == cardMessageId }) {
                if let data = try? JSONEncoder().encode(smartActions) {
                    cardMsg.actionsJSON = String(data: data, encoding: .utf8)
                }
            }

            // Auto-generate summary message below the card
            let autoSummary = contentType.generateAutoSummary(ocrText: ocrText)
            let summaryMessage = ChatMessage(
                content: autoSummary,
                role: "assistant",
                conversationId: conversation.id,
                toolBadge: contentType.displayLabel,
                actions: smartActions
            )
            context.insert(summaryMessage)
            try? context.save()

        } catch {
            // OCR failed — post a fallback message with basic actions
            let fallbackActions = [
                ChatAction(label: "Extract Text", icon: "text.viewfinder", actionType: .executeInline, fileId: documentId, payload: "ocr"),
                ChatAction(label: "Compress PDF", icon: "arrow.down.doc", actionType: .executeInline, fileId: documentId, payload: "compress"),
                ChatAction(label: "Share", icon: "square.and.arrow.up", actionType: .shareFile, fileId: documentId),
            ]
            let fallbackMsg = ChatMessage(
                content: "Document saved. What would you like to do with it?",
                role: "assistant",
                conversationId: conversation.id,
                actions: fallbackActions
            )
            context.insert(fallbackMsg)
            try? context.save()
        }
    }

    func executeInlineAction(toolType: String, documentFileId: String, context: ModelContext) {
        guard let conversation = currentConversation else { return }

        // Find the document
        let descriptor = FetchDescriptor<DocumentFile>()
        let allDocs = (try? context.fetch(descriptor)) ?? []
        guard let doc = allDocs.first(where: { $0.id.uuidString == documentFileId }) else { return }

        // Insert processing message
        let processingMsg = ChatMessage(
            content: processingText(for: toolType),
            role: "assistant",
            conversationId: conversation.id,
            messageType: "processing",
            documentFileId: documentFileId,
            inlineToolType: toolType
        )
        context.insert(processingMsg)
        try? context.save()

        Task { @MainActor [weak self] in
            guard let self else { return }
            let result = await self.inlineToolExecutor.execute(toolType: toolType, documentFile: doc, context: context)

            // Update processing message to result
            processingMsg.content = result.content
            processingMsg.messageType = "toolResult"
            if let data = try? JSONEncoder().encode(result) {
                processingMsg.resultDataJSON = String(data: data, encoding: .utf8) ?? ""
            }
            try? context.save()

            // For tools that produce output files (compress/watermark), show a document card + auto-summary
            if result.success, let outputId = result.outputFileId {
                let outputDocs = (try? context.fetch(FetchDescriptor<DocumentFile>())) ?? []
                if let outputDoc = outputDocs.first(where: { $0.id.uuidString == outputId }) {
                    self.handleAttachedDocument(documentId: outputId, document: outputDoc, context: context)
                    return
                }
            }

            // For text-only results (OCR/summarize), add follow-up actions
            let followUps = self.buildFollowUpActions(toolType: toolType, result: result, documentFileId: documentFileId)
            if !followUps.isEmpty {
                let followUpMsg = ChatMessage(
                    content: result.success ? "What would you like to do next?" : "Would you like to try something else?",
                    role: "assistant",
                    conversationId: conversation.id,
                    actions: followUps
                )
                context.insert(followUpMsg)
                try? context.save()
            }
        }
    }

    // MARK: - Tools Tab → Chat Integration

    /// Called when a PDF tool or converter finishes and produces a new document
    func handleToolOutput(documentId: String, toolName: String, context: ModelContext) {
        // Ensure we have a conversation
        if currentConversation == nil {
            startNewConversation(context: context)
        }
        guard let conversation = currentConversation else { return }

        // Find the document
        let descriptor = FetchDescriptor<DocumentFile>()
        let allDocs = (try? context.fetch(descriptor)) ?? []
        guard let doc = allDocs.first(where: { $0.id.uuidString == documentId }) else { return }

        // Create document card
        let actions = [
            ChatAction(label: "Extract Text", icon: "text.viewfinder", actionType: .executeInline, fileId: documentId, payload: "ocr"),
            ChatAction(label: "Summarize", icon: "doc.text.magnifyingglass", actionType: .executeInline, fileId: documentId, payload: "summarize"),
            ChatAction(label: "Compress PDF", icon: "arrow.down.doc", actionType: .executeInline, fileId: documentId, payload: "compress"),
            ChatAction(label: "Share", icon: "square.and.arrow.up", actionType: .shareFile, fileId: documentId),
        ]

        let cardMessage = ChatMessage(
            content: "\(toolName) complete — \(doc.fullFileName) is ready.",
            role: "assistant",
            conversationId: conversation.id,
            toolBadge: toolName,
            actions: actions,
            messageType: "documentCard",
            documentFileId: documentId
        )
        context.insert(cardMessage)
        try? context.save()

        // Background OCR → auto-summary
        if let fileURL = doc.fileURL {
            let cardMessageId = cardMessage.id
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.runBackgroundOCR(
                    documentId: documentId,
                    cardMessageId: cardMessageId,
                    fileURL: fileURL,
                    context: context
                )
            }
        }
    }

    private func processingText(for toolType: String) -> String {
        switch toolType {
        case "ocr": return "Extracting text from your document..."
        case "summarize": return "Generating summary..."
        case "compress": return "Compressing your PDF..."
        case "watermark": return "Adding watermark..."
        default: return "Processing..."
        }
    }

    private func buildFollowUpActions(toolType: String, result: InlineToolResult, documentFileId: String) -> [ChatAction] {
        guard result.success else { return [] }

        switch toolType {
        case "ocr":
            return [
                ChatAction(label: "Copy Text", icon: "doc.on.doc", actionType: .copyText, payload: result.content),
                ChatAction(label: "Summarize", icon: "doc.text.magnifyingglass", actionType: .executeInline, fileId: documentFileId, payload: "summarize"),
                ChatAction(label: "Share", icon: "square.and.arrow.up", actionType: .shareFile, fileId: documentFileId),
            ]
        case "summarize":
            return [
                ChatAction(label: "Copy Summary", icon: "doc.on.doc", actionType: .copyText, payload: result.content),
                ChatAction(label: "Share", icon: "square.and.arrow.up", actionType: .shareFile, fileId: documentFileId),
            ]
        case "compress":
            var actions: [ChatAction] = []
            if let outputId = result.outputFileId {
                actions.append(ChatAction(label: "Open File", icon: "doc", actionType: .openFile, fileId: outputId))
            }
            actions.append(ChatAction(label: "Share", icon: "square.and.arrow.up", actionType: .shareFile, fileId: result.outputFileId ?? documentFileId))
            return actions
        case "watermark":
            var actions: [ChatAction] = []
            if let outputId = result.outputFileId {
                actions.append(ChatAction(label: "Open File", icon: "doc", actionType: .openFile, fileId: outputId))
            }
            actions.append(ChatAction(label: "Share", icon: "square.and.arrow.up", actionType: .shareFile, fileId: result.outputFileId ?? documentFileId))
            return actions
        default:
            return []
        }
    }
}

struct QuickAction: Identifiable {
    let id = UUID()
    let label: String
    let icon: String
    let prompt: String
    var toolId: String?
}
