import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
@Observable
final class AIService {
    static let shared = AIService()

    enum AIBackend: String {
        case foundationModels
        case keywordMatching
    }

    private(set) var activeBackend: AIBackend
    private var provider: any AIResponseProvider

    var isOnDeviceAIAvailable: Bool {
        activeBackend == .foundationModels
    }

    private init() {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            let model = SystemLanguageModel.default
            if case .available = model.availability {
                let fmProvider = FoundationModelsProvider()
                self.provider = fmProvider
                self.activeBackend = .foundationModels
                return
            }
        }
        #endif
        self.provider = KeywordMatchingProvider()
        self.activeBackend = .keywordMatching
    }

    func generateResponse(for input: String, conversationHistory: [ChatMessage]) async throws -> AIResponse {
        do {
            return try await provider.generateResponse(for: input, conversationHistory: conversationHistory)
        } catch {
            if activeBackend == .foundationModels {
                return try await fallbackToKeywordMatching(for: input, conversationHistory: conversationHistory)
            }
            throw error
        }
    }

    func streamResponse(
        for input: String,
        conversationHistory: [ChatMessage],
        onPartialUpdate: @MainActor @Sendable (String) -> Void
    ) async throws -> AIResponse {
        do {
            return try await provider.streamResponse(
                for: input,
                conversationHistory: conversationHistory,
                onPartialUpdate: onPartialUpdate
            )
        } catch {
            if activeBackend == .foundationModels {
                return try await fallbackToKeywordMatching(for: input, conversationHistory: conversationHistory)
            }
            throw error
        }
    }

    private func fallbackToKeywordMatching(for input: String, conversationHistory: [ChatMessage]) async throws -> AIResponse {
        provider = KeywordMatchingProvider()
        activeBackend = .keywordMatching
        return try await provider.generateResponse(for: input, conversationHistory: conversationHistory)
    }

    var supportsStreaming: Bool { provider.supportsStreaming }

    func resetSession() { provider.resetSession() }
}
