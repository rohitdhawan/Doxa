import Foundation

@MainActor
final class KeywordMatchingProvider: AIResponseProvider {
    var supportsStreaming: Bool { false }

    private static let languageNames = [
        "hindi", "spanish", "french", "german", "chinese", "japanese", "korean",
        "arabic", "portuguese", "italian", "russian", "turkish", "urdu", "bengali",
        "tamil", "telugu", "marathi", "gujarati", "kannada", "malayalam", "punjabi",
        "english", "dutch", "polish", "thai", "vietnamese", "indonesian", "malay",
        "persian", "swedish", "greek", "czech", "romanian", "hungarian", "filipino",
        "hindhi", "espanol", "francais", "deutsch" // common misspellings/native names
    ]

    func generateResponse(for input: String, conversationHistory: [ChatMessage]) async throws -> AIResponse {
        try await Task.sleep(for: .milliseconds(800))

        // Check for document context first — handle questions about scanned/attached files
        if let docResponse = handleDocumentContextRequest(input: input) {
            return docResponse
        }

        let lower = input.lowercased()
        let response: String
        let badge: String?
        var chatActions: [ChatAction] = []

        if lower.contains("scan") {
            response = "I can help you scan a document! Tap the button below to open the scanner and capture pages with your camera."
            badge = "Scanner"
            chatActions = [
                ChatAction(label: "Open Scanner", icon: "doc.viewfinder", actionType: .openTool, toolId: "Scanner")
            ]
        } else if lower.contains("merge") {
            response = "To merge PDFs, select the files you want to combine, set the order, and tap Merge. The combined file will appear in your Files tab."
            badge = "Merge PDF"
            chatActions = [
                ChatAction(label: "Open Merge PDF", icon: "doc.on.doc.fill", actionType: .openTool, toolId: "Merge PDF"),
                ChatAction(label: "Go to Files", icon: "folder", actionType: .navigateTab, tabId: "files")
            ]
        } else if lower.contains("translate") || lower.contains("translation") || lower.contains("language") || hasLanguageName(lower) {
            // Translate BEFORE convert — "convert into hindi" should hit translate
            let detectedLang = Self.languageNames.first { lower.contains($0) }?.capitalized ?? "another language"
            response = "Translate your PDF content to \(detectedLang) using AI."
            badge = "Translate PDF"
            chatActions = [
                ChatAction(label: "Open Translate PDF", icon: "textformat.abc", actionType: .openTool, toolId: "Translate PDF")
            ]
        } else if lower.contains("convert") {
            response = "I can guide you through conversion! Choose a tool below:"
            badge = "Converter"
            chatActions = [
                ChatAction(label: "Image to PDF", icon: "photo.on.rectangle", actionType: .openTool, toolId: "Image to PDF"),
                ChatAction(label: "Doc to PDF", icon: "doc.text.fill", actionType: .openTool, toolId: "Doc to PDF"),
                ChatAction(label: "PDF to Image", icon: "photo", actionType: .openTool, toolId: "PDF to Image"),
                ChatAction(label: "PDF to Text", icon: "doc.plaintext", actionType: .openTool, toolId: "PDF to Text"),
            ]
        } else if lower.contains("ocr") || lower.contains("extract text") {
            response = "For text extraction, you have two options:"
            badge = "OCR"
            chatActions = [
                ChatAction(label: "OCR Text", icon: "text.viewfinder", actionType: .openTool, toolId: "OCR Text"),
                ChatAction(label: "PDF to Text", icon: "doc.plaintext", actionType: .openTool, toolId: "PDF to Text"),
            ]
        } else if lower.contains("compress") {
            response = "Compress your PDF to reduce file size. Choose from Low, Medium, or High compression."
            badge = "Compress"
            chatActions = [
                ChatAction(label: "Open Compress", icon: "arrow.down.doc", actionType: .openTool, toolId: "Compress")
            ]
        } else if lower.contains("watermark") {
            response = "Add text watermarks to your PDFs. The text appears diagonally across each page with transparency."
            badge = "Watermark"
            chatActions = [
                ChatAction(label: "Open Watermark", icon: "drop.triangle", actionType: .openTool, toolId: "Watermark")
            ]
        } else if lower.contains("lock") || lower.contains("password") || lower.contains("protect") {
            response = "You can protect your PDFs with a password or remove an existing one:"
            badge = "Lock/Unlock"
            chatActions = [
                ChatAction(label: "Lock PDF", icon: "lock.doc", actionType: .openTool, toolId: "Lock PDF"),
                ChatAction(label: "Unlock PDF", icon: "lock.open", actionType: .openTool, toolId: "Unlock PDF"),
            ]
        } else if lower.contains("split") {
            response = "Split a PDF into separate files by page range."
            badge = "Split PDF"
            chatActions = [
                ChatAction(label: "Open Split PDF", icon: "scissors", actionType: .openTool, toolId: "Split PDF")
            ]
        } else if lower.contains("rotate") {
            response = "Rotate PDF pages to the correct orientation."
            badge = "Rotate PDF"
            chatActions = [
                ChatAction(label: "Open Rotate PDF", icon: "rotate.right", actionType: .openTool, toolId: "Rotate PDF")
            ]
        } else if lower.contains("reorder") || lower.contains("rearrange") {
            response = "Rearrange pages in your PDF by dragging them into the desired order."
            badge = "Reorder Pages"
            chatActions = [
                ChatAction(label: "Open Reorder", icon: "arrow.up.arrow.down.square", actionType: .openTool, toolId: "Reorder Pages")
            ]
        } else if lower.contains("page number") {
            response = "Add page numbers to your PDF document."
            badge = "Page Numbers"
            chatActions = [
                ChatAction(label: "Open Page Numbers", icon: "number.square", actionType: .openTool, toolId: "Page Numbers")
            ]
        } else if lower.contains("extract") && lower.contains("page") {
            response = "Extract specific pages from a PDF into a new file."
            badge = "Extract Pages"
            chatActions = [
                ChatAction(label: "Open Extract Pages", icon: "doc.badge.plus", actionType: .openTool, toolId: "Extract Pages")
            ]
        } else if lower.contains("sign") || lower.contains("signature") {
            response = "Add your signature to a PDF. Draw your signature and place it on any page."
            badge = "Sign PDF"
            chatActions = [
                ChatAction(label: "Open Sign PDF", icon: "signature", actionType: .openTool, toolId: "Sign PDF")
            ]
        } else if lower.contains("crop") || lower.contains("trim") || lower.contains("margin") {
            response = "Crop your PDF by adjusting the margins on each side."
            badge = "Crop PDF"
            chatActions = [
                ChatAction(label: "Open Crop PDF", icon: "crop", actionType: .openTool, toolId: "Crop PDF")
            ]
        } else if lower.contains("metadata") || lower.contains("properties") || lower.contains("author") {
            response = "View and edit your PDF's metadata — title, author, subject, and keywords."
            badge = "PDF Metadata"
            chatActions = [
                ChatAction(label: "Open Metadata Editor", icon: "info.circle", actionType: .openTool, toolId: "PDF Metadata")
            ]
        } else if lower.contains("summarize") || lower.contains("summary") || lower.contains("tldr") {
            response = "Get an AI-powered summary of your PDF document."
            badge = "Summarize PDF"
            chatActions = [
                ChatAction(label: "Open Summarize PDF", icon: "text.badge.star", actionType: .openTool, toolId: "Summarize PDF")
            ]
        } else if lower.contains("ask") || lower.contains("question") {
            response = "Ask questions about your PDF and get AI-powered answers."
            badge = "Ask PDF"
            chatActions = [
                ChatAction(label: "Open Ask PDF", icon: "questionmark.bubble", actionType: .openTool, toolId: "Ask PDF")
            ]
        } else if lower.contains("email") || lower.contains("mail") {
            response = "Email your PDF as an attachment with an AI-generated description."
            badge = "Email PDF"
            chatActions = [
                ChatAction(label: "Open Email PDF", icon: "envelope", actionType: .openTool, toolId: "Email PDF")
            ]
        } else if lower.contains("hello") || lower.contains("hi") || lower.contains("hey") {
            response = "Hello! I'm Doxa, your AI document assistant. I can help you with scanning, PDF tools, converting files, and extracting text. What would you like to do?"
            badge = nil
            chatActions = [
                ChatAction(label: "Browse Tools", icon: "wrench.and.screwdriver", actionType: .navigateTab, tabId: "tools"),
                ChatAction(label: "View Files", icon: "folder", actionType: .navigateTab, tabId: "files"),
            ]
        } else {
            response = "I can help you with document tasks! Try asking me to scan, merge, convert, compress, or extract text. Or tap a quick action below."
            badge = nil
            chatActions = [
                ChatAction(label: "Scan Document", icon: "doc.viewfinder", actionType: .openTool, toolId: "Scanner"),
                ChatAction(label: "Browse All Tools", icon: "wrench.and.screwdriver", actionType: .navigateTab, tabId: "tools"),
            ]
        }

        return AIResponse(text: response, toolBadge: badge, actions: chatActions)
    }

    func streamResponse(
        for input: String,
        conversationHistory: [ChatMessage],
        onPartialUpdate: @MainActor @Sendable (String) -> Void
    ) async throws -> AIResponse {
        return try await generateResponse(for: input, conversationHistory: conversationHistory)
    }

    func resetSession() {}

    // MARK: - Document Context Handling

    private func hasLanguageName(_ text: String) -> Bool {
        Self.languageNames.contains { text.contains($0) }
    }

    /// Handle requests that include document OCR context
    private func handleDocumentContextRequest(input: String) -> AIResponse? {
        // Check if input contains document context
        guard input.contains("[Document context") else { return nil }

        // Extract OCR text and user question
        let parts = input.components(separatedBy: "User question: ")
        guard parts.count >= 2 else { return nil }
        let userQuestion = parts.last!.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Extract the OCR text between --- markers
        let ocrText: String
        if let startRange = input.range(of: "---\n"),
           let endRange = input.range(of: "\n---", range: startRange.upperBound..<input.endIndex) {
            ocrText = String(input[startRange.upperBound..<endRange.lowerBound])
        } else {
            ocrText = ""
        }

        let ocrPreview = String(ocrText.prefix(500))

        // Detect translation intent
        if hasLanguageName(userQuestion) || userQuestion.contains("translate") {
            let detectedLang = Self.languageNames.first { userQuestion.contains($0) }?.capitalized ?? "the requested language"
            let textPreview = String(ocrText.prefix(200)).trimmingCharacters(in: .whitespacesAndNewlines)

            return AIResponse(
                text: "To translate this document to **\(detectedLang)**, use the Translate PDF tool. Here's a preview of the text to translate:\n\n> \(textPreview)...",
                toolBadge: "Translate PDF",
                actions: [
                    ChatAction(label: "Translate PDF", icon: "textformat.abc", actionType: .openTool, toolId: "Translate PDF"),
                    ChatAction(label: "Copy Text", icon: "doc.on.doc", actionType: .copyText, payload: ocrText),
                ]
            )
        }

        // Detect amount/total/price questions
        if userQuestion.contains("total") || userQuestion.contains("amount") || userQuestion.contains("price")
            || userQuestion.contains("how much") || userQuestion.contains("cost") {
            // Search for lines containing monetary values
            let lines = ocrText.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            let moneyLines = lines.filter { line in
                let l = line.lowercased()
                return l.contains("$") || l.contains("total") || l.contains("amount")
                    || l.contains("price") || l.contains("subtotal") || l.contains("balance")
            }

            if !moneyLines.isEmpty {
                let found = moneyLines.prefix(5).map { "- \($0.trimmingCharacters(in: .whitespaces))" }.joined(separator: "\n")
                return AIResponse(
                    text: "Here's what I found in the document:\n\n\(found)",
                    toolBadge: "Document",
                    actions: [
                        ChatAction(label: "Copy Text", icon: "doc.on.doc", actionType: .copyText, payload: moneyLines.joined(separator: "\n")),
                        ChatAction(label: "Full Summary", icon: "doc.text.magnifyingglass", actionType: .openTool, toolId: "Summarize PDF"),
                    ]
                )
            }
        }

        // Detect general content questions (what, who, when, where, find, tell me, read, show)
        let questionKeywords = ["what", "who", "when", "where", "find", "tell me", "read", "show", "detail", "content", "say"]
        if questionKeywords.contains(where: { userQuestion.contains($0) }) {
            // Search for lines matching keywords from the question
            let questionWords = userQuestion.split(separator: " ")
                .map { String($0) }
                .filter { $0.count > 3 } // skip short words

            let lines = ocrText.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            let relevantLines = lines.filter { line in
                let l = line.lowercased()
                return questionWords.contains { l.contains($0) }
            }

            if !relevantLines.isEmpty {
                let found = relevantLines.prefix(5).map { "- \($0.trimmingCharacters(in: .whitespaces))" }.joined(separator: "\n")
                return AIResponse(
                    text: "Here's what I found:\n\n\(found)",
                    toolBadge: "Document",
                    actions: [
                        ChatAction(label: "Copy Text", icon: "doc.on.doc", actionType: .copyText, payload: relevantLines.joined(separator: "\n")),
                        ChatAction(label: "Extract All Text", icon: "text.viewfinder", actionType: .openTool, toolId: "OCR Text"),
                    ]
                )
            }

            // Fallback: show OCR preview
            return AIResponse(
                text: "Here's the document content:\n\n> \(ocrPreview)...",
                toolBadge: "Document",
                actions: [
                    ChatAction(label: "Copy Text", icon: "doc.on.doc", actionType: .copyText, payload: ocrText),
                    ChatAction(label: "Summarize", icon: "doc.text.magnifyingglass", actionType: .openTool, toolId: "Summarize PDF"),
                ]
            )
        }

        // Detect summarize intent
        if userQuestion.contains("summarize") || userQuestion.contains("summary") || userQuestion.contains("brief") || userQuestion.contains("tldr") {
            let sentences = ocrText.components(separatedBy: CharacterSet(charactersIn: ".!?"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.count > 15 }
            let summary = sentences.prefix(4).enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
            let wordCount = ocrText.split(separator: " ").count

            return AIResponse(
                text: "**Summary** (~\(wordCount) words):\n\n\(summary)",
                toolBadge: "Document",
                actions: [
                    ChatAction(label: "Copy Summary", icon: "doc.on.doc", actionType: .copyText, payload: summary),
                    ChatAction(label: "Full AI Summary", icon: "doc.text.magnifyingglass", actionType: .openTool, toolId: "Summarize PDF"),
                ]
            )
        }

        // Default: no special handling, let normal keyword matching proceed
        return nil
    }
}
