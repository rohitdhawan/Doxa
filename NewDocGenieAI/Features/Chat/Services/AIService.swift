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

    struct OnDeviceAIStatus: Equatable {
        let isAvailable: Bool
        let title: String
        let message: String

        static let available = OnDeviceAIStatus(
            isAvailable: true,
            title: "On-Device AI Ready",
            message: "Apple Intelligence is ready for AI document tools."
        )
    }

    private(set) var activeBackend: AIBackend
    private var provider: any AIResponseProvider

    var isOnDeviceAIAvailable: Bool {
        onDeviceAIStatus.isAvailable
    }

    var onDeviceAIStatus: OnDeviceAIStatus {
        Self.currentOnDeviceAIStatus()
    }

    private init() {
        self.provider = KeywordMatchingProvider()
        self.activeBackend = .keywordMatching
        refreshProviderForCurrentAvailability()
    }

    func refreshProviderForCurrentAvailability() {
        #if canImport(FoundationModels)
        guard #available(iOS 26, *) else {
            if activeBackend == .foundationModels {
                provider = KeywordMatchingProvider()
                activeBackend = .keywordMatching
            }
            return
        }

        if onDeviceAIStatus.isAvailable {
            if activeBackend != .foundationModels {
                provider = FoundationModelsProvider()
                activeBackend = .foundationModels
            }
        } else if activeBackend == .foundationModels {
            provider = KeywordMatchingProvider()
            activeBackend = .keywordMatching
        }
        #endif
    }

    func generateResponse(for input: String, conversationHistory: [ChatMessage]) async throws -> AIResponse {
        refreshProviderForCurrentAvailability()
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
        refreshProviderForCurrentAvailability()
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

    private static func currentOnDeviceAIStatus() -> OnDeviceAIStatus {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return .available
            case .unavailable(.deviceNotEligible):
                return OnDeviceAIStatus(
                    isAvailable: false,
                    title: "Device Not Eligible",
                    message: "This iPhone does not support Apple Intelligence, even if it is running iOS 26.2."
                )
            case .unavailable(.appleIntelligenceNotEnabled):
                return OnDeviceAIStatus(
                    isAvailable: false,
                    title: "Apple Intelligence Off",
                    message: "Turn on Apple Intelligence in Settings, then reopen the app."
                )
            case .unavailable(.modelNotReady):
                return OnDeviceAIStatus(
                    isAvailable: false,
                    title: "AI Model Not Ready",
                    message: "Apple Intelligence is still downloading or preparing the on-device model."
                )
            @unknown default:
                return OnDeviceAIStatus(
                    isAvailable: false,
                    title: "AI Unavailable",
                    message: "Apple Intelligence is unavailable on this device right now."
                )
            }
        }

        return OnDeviceAIStatus(
            isAvailable: false,
            title: "Requires iOS 26",
            message: "Update this device to iOS 26 or later to use on-device AI translation."
        )
        #else
        return OnDeviceAIStatus(
            isAvailable: false,
            title: "Unsupported SDK",
            message: "Build the app with an SDK that includes FoundationModels."
        )
        #endif
    }
}
