import SwiftUI

// MARK: - Glass Card Modifier
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppCornerRadius.lg

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.appGlassStroke, lineWidth: 1)
            )
    }
}

// MARK: - Glow Modifier
struct GlowModifier: ViewModifier {
    var color: Color = .appPrimary
    var radius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.2), radius: radius * 2, x: 0, y: 4)
    }
}

// MARK: - Shimmer Modifier
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -300
    @State private var isActive = false

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.12), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(20))
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                isActive = true
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
            .onDisappear {
                isActive = false
            }
    }
}

// MARK: - Animated Gradient View
struct AnimatedGradientView: View {
    @State private var animateGradient = false
    var colors: [Color] = [.appPrimary, .appAccent, .appPrimary]

    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
        .onDisappear {
            animateGradient = false
        }
    }
}

// MARK: - View Extensions
extension View {
    func glassCard(cornerRadius: CGFloat = AppCornerRadius.lg) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }

    func glow(color: Color = .appPrimary, radius: CGFloat = 12) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }

    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
