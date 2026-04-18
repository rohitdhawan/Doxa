import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Color.appTextDim)
                .symbolEffect(.pulse, options: .repeating)

            Text(title)
                .font(.appH3)
                .foregroundStyle(Color.appText)

            Text(message)
                .font(.appCaption)
                .foregroundStyle(Color.appTextMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)

            if let buttonTitle, let action {
                PrimaryButton(title: buttonTitle, action: action)
                    .padding(.horizontal, AppSpacing.xxl)
                    .padding(.top, AppSpacing.sm)
            }
        }
        .padding(AppSpacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}
