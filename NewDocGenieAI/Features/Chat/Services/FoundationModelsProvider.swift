import Foundation
#if canImport(FoundationModels)
import FoundationModels

// MARK: - Tool Definitions

@available(iOS 26, *)
struct SuggestToolDefinition: Tool {
    let name = "suggestTool"
    let description = "Suggest an app tool for the user. Creates an action button in the chat."

    @Generable
    struct Arguments {
        @Guide(description: "Tool ID. Must be one of: Scanner, Merge PDF, Split PDF, Compress, Lock PDF, Unlock PDF, Extract Pages, Rotate PDF, Reorder Pages, Page Numbers, Watermark, OCR Text, Sign PDF, Crop PDF, PDF Metadata, Image to PDF, Doc to PDF, PDF to Image, PDF to Text, Summarize PDF, Ask PDF, Translate PDF, Email PDF")
        var toolId: String
        @Guide(description: "Button label shown to the user, e.g. 'Open Scanner'")
        var label: String
    }

    func call(arguments: Arguments) async throws -> String {
        "Tool suggested: \(arguments.label)"
    }
}

@available(iOS 26, *)
struct NavigateTabDefinition: Tool {
    let name = "navigateTab"
    let description = "Navigate the user to a specific tab. Use when they want to browse tools or view files."

    @Generable
    struct Arguments {
        @Guide(description: "Tab to navigate to. Must be 'tools' or 'files'")
        var tabId: String
        @Guide(description: "Button label shown to the user, e.g. 'Browse Tools'")
        var label: String
    }

    func call(arguments: Arguments) async throws -> String {
        "Navigating to \(arguments.tabId) tab"
    }
}

// MARK: - Provider

@available(iOS 26, *)
@MainActor
final class FoundationModelsProvider: AIResponseProvider {
    var supportsStreaming: Bool { true }

    private var session: LanguageModelSession?

    private static let systemInstructions = """
    You are Doxa, a friendly AI document assistant inside the Doxa app.
    Help users with document management tasks. Keep responses to 2-3 sentences.
    Be action-oriented — suggest the right tool for the user's request.

    Available tools (use suggestTool to recommend):
    Scanner, Merge PDF, Split PDF, Compress, Lock PDF, Unlock PDF, Extract Pages, \
    Rotate PDF, Reorder Pages, Page Numbers, Watermark, OCR Text, Sign PDF, \
    Crop PDF, PDF Metadata, Image to PDF, Doc to PDF, PDF to Image, PDF to Text, \
    Summarize PDF, Ask PDF, Translate PDF, Email PDF

    Use navigateTab to send users to the "tools" or "files" tab.
    Always call suggestTool when you identify a relevant tool for the user's request.

    IMPORTANT — Document context handling:
    When the user's message includes "[Document context from scanned/attached file]", \
    the user is asking about a scanned or attached document. In this case:
    - Answer questions DIRECTLY from the document text provided — do not just redirect to a tool.
    - If the user mentions a language name (e.g. "hindi", "spanish", "french") or says \
    "convert into [language]" or "translate", they want TRANSLATION — do NOT suggest \
    file conversion tools. Suggest "Translate PDF" tool instead, and show a preview of \
    the translated content if possible.
    - For questions like "how much", "what is the total", "find the date" — extract the \
    answer directly from the document text and show it.
    - For "summarize" or "details" — summarize the document content inline.
    - Only suggest tools (via suggestTool) if the user explicitly asks for a tool \
    operation like compress, merge, watermark, sign, lock, etc.
    """

    private func getOrCreateSession() -> LanguageModelSession {
        if let session { return session }
        let newSession = LanguageModelSession(
            tools: [SuggestToolDefinition(), NavigateTabDefinition()],
            instructions: Self.systemInstructions
        )
        session = newSession
        return newSession
    }

    func generateResponse(for input: String, conversationHistory: [ChatMessage]) async throws -> AIResponse {
        let session = getOrCreateSession()
        do {
            let response = try await session.respond(to: input)
            let actions = extractActions(from: response.transcriptEntries)
            let badge = determineBadge(from: actions)
            return AIResponse(text: response.content, toolBadge: badge, actions: actions)
        } catch {
            throw AIServiceError.responseGenerationFailed(underlying: error)
        }
    }

    func streamResponse(
        for input: String,
        conversationHistory: [ChatMessage],
        onPartialUpdate: @MainActor @Sendable (String) -> Void
    ) async throws -> AIResponse {
        let session = getOrCreateSession()
        do {
            var finalText = ""
            let stream = session.streamResponse(to: input)
            for try await partial in stream {
                finalText = partial.content
                onPartialUpdate(finalText)
            }

            // After streaming, get the transcript entries from the session
            let actions = extractActionsFromSession(session)
            let badge = determineBadge(from: actions)
            return AIResponse(text: finalText, toolBadge: badge, actions: actions)
        } catch {
            throw AIServiceError.responseGenerationFailed(underlying: error)
        }
    }

    func resetSession() {
        session = nil
    }

    // MARK: - Action Extraction

    private func extractActions(from entries: ArraySlice<Transcript.Entry>) -> [ChatAction] {
        var actions: [ChatAction] = []
        for entry in entries {
            if case .toolCalls(let toolCalls) = entry {
                for call in toolCalls {
                    if let action = mapToolCall(call) {
                        actions.append(action)
                    }
                }
            }
        }
        return actions
    }

    private func extractActionsFromSession(_ session: LanguageModelSession) -> [ChatAction] {
        var actions: [ChatAction] = []
        // Walk backwards to find the most recent tool calls
        for entry in session.transcript.reversed() {
            if case .toolCalls(let toolCalls) = entry {
                for call in toolCalls {
                    if let action = mapToolCall(call) {
                        actions.insert(action, at: 0)
                    }
                }
                break
            }
        }
        return actions
    }

    private func mapToolCall(_ call: Transcript.ToolCall) -> ChatAction? {
        switch call.toolName {
        case "suggestTool":
            guard let args = try? call.arguments.value(SuggestToolDefinition.Arguments.self) else { return nil }
            let icon = ToolItem(rawValue: args.toolId)?.systemImage ?? "wrench"
            return ChatAction(
                label: args.label,
                icon: icon,
                actionType: .openTool,
                toolId: args.toolId
            )
        case "navigateTab":
            guard let args = try? call.arguments.value(NavigateTabDefinition.Arguments.self) else { return nil }
            let icon = args.tabId == "files" ? "folder" : "wrench.and.screwdriver"
            return ChatAction(
                label: args.label,
                icon: icon,
                actionType: .navigateTab,
                tabId: args.tabId
            )
        default:
            return nil
        }
    }

    private func determineBadge(from actions: [ChatAction]) -> String? {
        actions.first(where: { $0.actionType == .openTool })?.toolId
    }
}

#endif
