import SwiftUI
import SwiftData

@MainActor
@Observable
final class AIDocumentViewModel {
    var isProcessing = false
    var didComplete = false
    var errorMessage: String?
    var showError = false
    var resultText: String?
    var resultFileName: String?

    var extractedDocumentText: String?
    var chatMessages: [(role: String, content: String)] = []

    private let ocrService = OCRService.shared
    private let converterService = ConverterService.shared

    // MARK: - Summarize

    func summarizePDF(url: URL) {
        isProcessing = true
        Task { @MainActor in
            defer { isProcessing = false }
            do {
                let text = try await ocrService.extractText(from: url)

                if AIService.shared.isOnDeviceAIAvailable {
                    let prompt = "Summarize the following document in 3-5 key bullet points. Be concise and clear:\n\n\(String(text.prefix(4000)))"
                    let response = try await AIService.shared.generateResponse(for: prompt, conversationHistory: [])
                    resultText = response.text
                } else {
                    resultText = generateBasicSummary(text: text)
                }
                didComplete = true
                HapticManager.success()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                HapticManager.error()
            }
        }
    }

    // MARK: - Ask PDF

    func loadDocument(url: URL) {
        isProcessing = true
        Task { @MainActor in
            defer { isProcessing = false }
            do {
                extractedDocumentText = try await ocrService.extractText(from: url)
                chatMessages.append((role: "assistant", content: "Document loaded. Ask me anything about it."))
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                HapticManager.error()
            }
        }
    }

    func askQuestion(_ question: String) {
        guard let docText = extractedDocumentText else { return }
        chatMessages.append((role: "user", content: question))
        isProcessing = true

        Task { @MainActor in
            defer { isProcessing = false }
            do {
                if AIService.shared.isOnDeviceAIAvailable {
                    let prompt = """
                    Based on this document content, answer the question concisely.

                    Document (excerpt):
                    \(String(docText.prefix(3000)))

                    Question: \(question)
                    """
                    let response = try await AIService.shared.generateResponse(for: prompt, conversationHistory: [])
                    chatMessages.append((role: "assistant", content: response.text))
                } else {
                    let results = searchKeywords(question: question, in: docText)
                    chatMessages.append((role: "assistant", content: results))
                }
            } catch {
                chatMessages.append((role: "assistant", content: "Sorry, I couldn't process your question. \(error.localizedDescription)"))
            }
        }
    }

    // MARK: - Translate

    func translatePDF(url: URL, targetLanguage: String) {
        isProcessing = true
        Task { @MainActor in
            defer { isProcessing = false }
            do {
                let text = try await ocrService.extractText(from: url)

                let aiStatus = AIService.shared.onDeviceAIStatus
                guard aiStatus.isAvailable else {
                    errorMessage = "\(aiStatus.title): \(aiStatus.message)"
                    showError = true
                    return
                }

                var translated = ""
                let chunks = text.chunked(maxLength: 2000)
                for chunk in chunks {
                    let prompt = "Translate the following text to \(targetLanguage). Only output the translation, nothing else:\n\n\(chunk)"
                    let response = try await AIService.shared.generateResponse(for: prompt, conversationHistory: [])
                    translated += response.text + "\n\n"
                }

                resultText = translated.trimmingCharacters(in: .whitespacesAndNewlines)
                didComplete = true
                HapticManager.success()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                HapticManager.error()
            }
        }
    }

    // MARK: - Save

    func saveResultAsText(outputName: String, context: ModelContext) {
        guard let text = resultText else { return }
        isProcessing = true
        defer { isProcessing = false }
        do {
            let result = try converterService.saveTextFile(text: text, outputName: outputName)
            let metadata = FileMetadataService.shared.extractMetadata(from: result.url)
            let docFile = DocumentFile(
                name: (result.url.lastPathComponent as NSString).deletingPathExtension,
                fileExtension: "txt",
                relativeFilePath: result.relativePath,
                fileSize: metadata.fileSize
            )
            context.insert(docFile)
            try context.save()
            resultFileName = docFile.fullFileName
            HapticManager.success()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.error()
        }
    }

    func reset() {
        isProcessing = false
        didComplete = false
        errorMessage = nil
        showError = false
        resultText = nil
        resultFileName = nil
        chatMessages = []
        extractedDocumentText = nil
    }

    // MARK: - Helpers

    private func generateBasicSummary(text: String) -> String {
        let words = text.split(separator: " ")
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let firstParagraph = String(text.prefix(500))
        return """
        Document Statistics:
        \u{2022} Word count: \(words.count)
        \u{2022} Line count: \(lines.count)
        \u{2022} Character count: \(text.count)

        Preview:
        \(firstParagraph)\(text.count > 500 ? "..." : "")
        """
    }

    private func searchKeywords(question: String, in text: String) -> String {
        let keywords = question.lowercased().split(separator: " ").filter { $0.count > 3 }
        let sentences = text.components(separatedBy: ". ")
        let matches = sentences.filter { sentence in
            keywords.contains { sentence.lowercased().contains($0) }
        }.prefix(5)

        if matches.isEmpty {
            return "No relevant sections found. Try different keywords."
        }
        return "Relevant excerpts:\n\n" + matches.joined(separator: "\n\n")
    }
}

private extension String {
    func chunked(maxLength: Int) -> [String] {
        var chunks: [String] = []
        var current = startIndex
        while current < endIndex {
            let end = index(current, offsetBy: maxLength, limitedBy: endIndex) ?? endIndex
            chunks.append(String(self[current..<end]))
            current = end
        }
        return chunks
    }
}
