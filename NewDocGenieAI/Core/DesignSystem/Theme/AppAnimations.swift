import SwiftUI

enum AppAnimations {
    static let springBounce = Animation.spring(response: 0.4, dampingFraction: 0.65, blendDuration: 0)
    static let springSmooth = Animation.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0)
    static let springQuick = Animation.spring(response: 0.25, dampingFraction: 0.75, blendDuration: 0)
    static let easeOut = Animation.easeOut(duration: 0.25)
    static let easeInOut = Animation.easeInOut(duration: 0.3)
    static let slowEase = Animation.easeInOut(duration: 0.6)

    static func stagger(index: Int, base: Animation = .spring(response: 0.4, dampingFraction: 0.75)) -> Animation {
        base.delay(Double(index) * 0.05)
    }
}

struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .onAppear {
                withAnimation(AppAnimations.stagger(index: index)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func staggeredAppear(index: Int) -> some View {
        modifier(StaggeredAppearModifier(index: index))
    }
}
