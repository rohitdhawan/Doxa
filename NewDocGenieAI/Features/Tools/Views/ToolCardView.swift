import SwiftUI

struct ToolCardView: View {
    let tool: ToolItem
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            VStack(spacing: AppSpacing.sm) {
                GlowingIcon(
                    systemName: tool.systemImage,
                    color: tool.color,
                    size: 28,
                    bgSize: 52
                )

                Text(tool.rawValue)
                    .font(.appH3)
                    .foregroundStyle(Color.appText)

                Text(tool.description)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextMuted)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.lg)
            .glassCard()
        }
        .buttonStyle(.scale)
        .accessibilityLabel("\(tool.rawValue), \(tool.description)")
        .accessibilityHint("Double tap to open tool")
    }
}
