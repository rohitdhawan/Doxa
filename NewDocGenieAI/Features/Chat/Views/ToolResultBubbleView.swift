import SwiftUI
import UIKit

struct ToolResultBubbleView: View {
    let message: ChatMessage
    var onAction: ((ChatAction) -> Void)?

    @State private var isExpanded = false
    @State private var showSuccessGlow = false

    private var result: InlineToolResult? {
        guard !message.resultDataJSON.isEmpty,
              let data = message.resultDataJSON.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(InlineToolResult.self, from: data)
    }

    var body: some View {
        let toolResult = result
        let isSuccess = toolResult?.success ?? false
        let statusColor: Color = isSuccess ? .appAccent : .appDanger

        HStack(alignment: .top) {
            // AI avatar
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.appPrimary)
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                // Badge
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 10))
                    Text(toolResult?.title ?? "Result")
                        .font(.appMicro)
                }
                .foregroundStyle(Color.appPrimary)

                // Result Card
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    // Header with copy button
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(statusColor)
                            .font(.system(size: 18))
                        Text(toolResult?.title ?? "Result")
                            .font(.appBody)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.appText)

                        Spacer()

                        if isSuccess {
                            Button {
                                UIPasteboard.general.string = toolResult?.content ?? ""
                                HapticManager.success()
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.appTextMuted)
                                    .padding(6)
                                    .background(Color.appBGDark.opacity(0.5), in: Circle())
                            }
                        }
                    }

                    // Content with expand/collapse
                    let content = toolResult?.content ?? message.content
                    if !content.isEmpty {
                        let isLongContent = content.count > 200

                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(content)
                                .font(.appCaption)
                                .foregroundStyle(Color.appText)
                                .lineLimit(isExpanded ? nil : 5)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if isLongContent {
                                Button {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        isExpanded.toggle()
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(isExpanded ? "Show Less" : "Show More")
                                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    }
                                    .font(.appMicro)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.appPrimary)
                                }
                            }
                        }
                        .padding(AppSpacing.sm)
                        .background(Color.appBGDark.opacity(0.5), in: RoundedRectangle(cornerRadius: AppCornerRadius.md))
                    }

                    // Compression comparison bar
                    if toolResult?.toolType == "compress" && isSuccess,
                       let original = toolResult?.originalSize, let compressed = toolResult?.compressedSize,
                       original > 0 {
                        CompressionComparisonBar(originalSize: original, compressedSize: compressed)
                    }

                    // Output file mini card
                    if let fileName = toolResult?.outputFileName {
                        HStack(spacing: AppSpacing.sm) {
                            FileTypeIcon(fileExtension: fileName.components(separatedBy: ".").last ?? "pdf", size: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(fileName)
                                    .font(.appCaption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.appText)
                                    .lineLimit(1)
                                Text("Ready to view")
                                    .font(.appMicro)
                                    .foregroundStyle(Color.appAccent)
                            }

                            Spacer()

                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.appAccent)
                        }
                        .padding(AppSpacing.sm)
                        .background(Color.appAccent.opacity(0.08), in: RoundedRectangle(cornerRadius: AppCornerRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                                .stroke(Color.appAccent.opacity(0.2), lineWidth: 1)
                        )
                    }

                    // Action buttons
                    let actions = message.actions
                    if !actions.isEmpty {
                        HStack(spacing: AppSpacing.sm) {
                            ForEach(actions) { action in
                                Button {
                                    HapticManager.light()
                                    onAction?(action)
                                } label: {
                                    HStack(spacing: AppSpacing.xs) {
                                        Image(systemName: action.icon)
                                            .font(.system(size: 11))
                                        Text(action.label)
                                            .font(.appCaption)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundStyle(statusColor)
                                    .padding(.horizontal, AppSpacing.md)
                                    .padding(.vertical, AppSpacing.sm)
                                    .background(statusColor.opacity(0.12), in: Capsule())
                                }
                                .buttonStyle(.scale)
                            }
                        }
                    }
                }
                .padding(AppSpacing.md)
                .glassCard(cornerRadius: AppCornerRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                        .stroke(statusColor.opacity(showSuccessGlow ? 0.6 : 0.3), lineWidth: showSuccessGlow ? 2 : 1)
                )
                .glow(color: showSuccessGlow ? statusColor : .clear, radius: showSuccessGlow ? 10 : 0)
            }

            Spacer(minLength: 20)
        }
        .onAppear {
            if result?.success == true {
                withAnimation(.easeOut(duration: 0.4)) { showSuccessGlow = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.8)) { showSuccessGlow = false }
                }
            }
        }
    }
}
