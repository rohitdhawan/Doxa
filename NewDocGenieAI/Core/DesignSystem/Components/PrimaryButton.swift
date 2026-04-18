import SwiftUI

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.medium()
            action()
        }) {
            HStack(spacing: AppSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Text(title)
                        .font(.appH3)
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.appGradientPrimary, in: RoundedRectangle(cornerRadius: AppCornerRadius.md))
            .glow(color: .appPrimary, radius: 6)
        }
        .buttonStyle(.scale)
        .disabled(isLoading)
        .opacity(isLoading ? 0.8 : 1)
        .accessibilityLabel(title)
        .accessibilityHint(isLoading ? "Loading" : "Double tap to activate")
    }
}
