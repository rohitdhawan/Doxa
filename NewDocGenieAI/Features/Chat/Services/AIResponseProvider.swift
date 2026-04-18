import Foundation

struct AIResponse: Sendable {
    let text: String
    let toolBadge: String?
    let actions: [ChatAction]
}

@MainActor
protocol AIResponseProvider {
    func generateResponse(for input: String, conversationHistory: [ChatMessage]) async throws -> AIResponse
    func streamResponse(
        for input: String,
        conversationHistory: [ChatMessage],
        onPartialUpdate: @MainActor @Sendable (String) -> Void
    ) async throws -> AIResponse
    var supportsStreaming: Bool { get }
    func resetSession()
}

enum AIServiceError: LocalizedError {
    case modelUnavailable
    case responseGenerationFailed(underlying: Error)
    case tokenLimitExceeded

    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "On-device AI model is not available."
        case .responseGenerationFailed(let error):
            return "Failed to generate response: \(error.localizedDescription)"
        case .tokenLimitExceeded:
            return "Conversation is too long. Please start a new chat."
        }
    }
}
