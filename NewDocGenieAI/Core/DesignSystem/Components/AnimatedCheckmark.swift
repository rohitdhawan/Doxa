import SwiftUI

struct AnimatedCheckmark: View {
    var color: Color = .appSuccess
    var size: CGFloat = 64
    @State private var trimEnd: CGFloat = 0
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)
                .glow(color: color, radius: 16)

            CheckmarkShape()
                .trim(from: 0, to: trimEnd)
                .stroke(color, style: StrokeStyle(lineWidth: size * 0.06, lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.45, height: size * 0.45)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(AppAnimations.springBounce) {
                scale = 1.0
                opacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.15)) {
                trimEnd = 1.0
            }
            HapticManager.success()
        }
        .accessibilityLabel("Operation completed successfully")
    }
}

private struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width * 0.35, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}
