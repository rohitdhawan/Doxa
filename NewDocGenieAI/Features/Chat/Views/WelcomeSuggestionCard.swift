import SwiftUI

struct WelcomeSuggestionCard: View {
    let action: QuickAction
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.sm) {
                GlowingIcon(systemName: action.icon, color: .appPrimary, size: 16, bgSize: 34)

                VStack(alignment: .leading, spacing: 2) {
                    Text(action.label)
                        .font(.appCaption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.appText)
                    Text(action.prompt)
                        .font(.appMicro)
                        .foregroundStyle(Color.appTextMuted)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.appTextDim)
            }
            .padding(AppSpacing.sm)
            .glassCard(cornerRadius: AppCornerRadius.md)
        }
        .buttonStyle(.scale)
    }
}
