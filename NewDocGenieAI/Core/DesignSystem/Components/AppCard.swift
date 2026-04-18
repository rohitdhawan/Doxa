import SwiftUI

enum CardStyle {
    case solid
    case glass
}

struct AppCard<Content: View>: View {
    var style: CardStyle = .solid
    @ViewBuilder let content: Content

    var body: some View {
        switch style {
        case .solid:
            content
                .padding(AppSpacing.md)
                .background(Color.appBGCard, in: RoundedRectangle(cornerRadius: AppCornerRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
        case .glass:
            content
                .padding(AppSpacing.md)
                .glassCard()
        }
    }
}
