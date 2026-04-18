import SwiftUI

struct QuickActionsView: View {
    let actions: [QuickAction]
    let onTap: (QuickAction) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(actions) { action in
                    Button {
                        HapticManager.light()
                        onTap(action)
                    } label: {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: action.icon)
                                .font(.system(size: 14))
                            Text(action.label)
                                .font(.appCaption)
                        }
                        .foregroundStyle(Color.appPrimary)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            Color.appPrimary.opacity(0.1),
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.appPrimary.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.scale)
                    .shadow(color: Color.appPrimary.opacity(0.15), radius: 4)
                    .accessibilityLabel(action.label)
                    .accessibilityHint("Double tap to \(action.prompt.lowercased())")
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
        .accessibilityLabel("Quick actions")
    }
}
