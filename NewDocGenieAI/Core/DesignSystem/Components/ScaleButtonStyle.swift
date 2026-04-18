import SwiftUI

struct ScaleButtonStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.95

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .animation(AppAnimations.springQuick, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ScaleButtonStyle {
    static var scale: ScaleButtonStyle { ScaleButtonStyle() }
    static func scale(_ amount: CGFloat) -> ScaleButtonStyle {
        ScaleButtonStyle(scaleAmount: amount)
    }
}
