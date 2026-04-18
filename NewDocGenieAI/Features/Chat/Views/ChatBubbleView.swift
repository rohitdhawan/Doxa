import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage
    var onAction: ((ChatAction) -> Void)?

    var body: some View {
        switch message.messageType {
        case "documentCard":
            DocumentCardBubbleView(message: message, onAction: onAction)
                .padding(.horizontal, AppSpacing.sm)
        case "processing":
            ProcessingBubbleView(message: message)
                .padding(.horizontal, AppSpacing.sm)
        case "toolResult":
            ToolResultBubbleView(message: message, onAction: onAction)
                .padding(.horizontal, AppSpacing.sm)
        default:
            DefaultChatBubbleView(message: message, onAction: onAction)
        }
    }
}

private struct DefaultChatBubbleView: View {
    let message: ChatMessage
    var onAction: ((ChatAction) -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            if message.isUser { Spacer(minLength: 60) }

            // AI avatar
            if message.isAssistant {
                ZStack {
                    Circle()
                        .fill(Color.appPrimary.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.appPrimary)
                }
                .padding(.top, 2)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: AppSpacing.xs) {
                if let badge = message.toolBadge {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.system(size: 10))
                        Text(badge)
                            .font(.appMicro)
                    }
                    .foregroundStyle(Color.appAccent)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 2)
                    .background(Color.appAccent.opacity(0.1), in: Capsule())
                    .glow(color: .appAccent, radius: 4)
                }

                Text(LocalizedStringKey(message.content))
                    .font(.appBody)
                    .foregroundStyle(message.isUser ? .white : Color.appText)
                    .multilineTextAlignment(message.isUser ? .trailing : .leading)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background {
                        RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                            .fill(
                                message.isUser
                                    ? AnyShapeStyle(
                                        LinearGradient(
                                            colors: [Color.appPrimary, Color.appPrimaryLight],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    : AnyShapeStyle(Color.appBGCard)
                            )
                    }
                    .overlay(
                        message.isUser ? nil :
                        RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )

                if !message.actions.isEmpty && message.isAssistant {
                    ChatActionButtonsView(actions: message.actions) { action in
                        onAction?(action)
                    }
                    .padding(.top, 2)
                }
            }

            if message.isAssistant { Spacer(minLength: 60) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(message.isUser ? "You" : "Doxa"): \(message.content)")
    }
}
