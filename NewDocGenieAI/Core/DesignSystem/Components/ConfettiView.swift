import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var startTime: Date = .now

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startTime)
            Canvas { context, size in
                for particle in particles {
                    let age = elapsed - particle.delay
                    guard age > 0 else { continue }

                    let progress = min(age / particle.lifetime, 1.0)
                    let x = particle.startX * size.width + particle.drift * CGFloat(age)
                    let y = particle.startY + particle.speed * CGFloat(age * age) * 0.5
                    let opacity = 1.0 - pow(progress, 2)
                    let rotation = Angle.degrees(particle.spin * age)

                    guard opacity > 0.01 else { continue }

                    context.opacity = opacity
                    context.translateBy(x: x, y: y)
                    context.rotate(by: rotation)

                    let rect = CGRect(
                        x: -particle.size / 2,
                        y: -particle.size / 2,
                        width: particle.size,
                        height: particle.size * (particle.isRound ? 1 : 0.6)
                    )

                    if particle.isRound {
                        context.fill(
                            Circle().path(in: rect),
                            with: .color(particle.color)
                        )
                    } else {
                        context.fill(
                            RoundedRectangle(cornerRadius: 2).path(in: rect),
                            with: .color(particle.color)
                        )
                    }

                    context.rotate(by: -rotation)
                    context.translateBy(x: -x, y: -y)
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onAppear {
            startTime = .now
            particles = (0..<60).map { _ in ConfettiParticle.random() }
        }
    }
}

private struct ConfettiParticle {
    let startX: CGFloat
    let startY: CGFloat
    let speed: CGFloat
    let drift: CGFloat
    let spin: Double
    let size: CGFloat
    let color: Color
    let isRound: Bool
    let delay: Double
    let lifetime: Double

    static func random() -> ConfettiParticle {
        let colors: [Color] = [
            .red, .orange, .yellow, .green, .blue, .purple, .pink, .mint, .cyan
        ]
        return ConfettiParticle(
            startX: CGFloat.random(in: 0.1...0.9),
            startY: CGFloat.random(in: -40...(-10)),
            speed: CGFloat.random(in: 180...350),
            drift: CGFloat.random(in: -40...40),
            spin: Double.random(in: -360...360),
            size: CGFloat.random(in: 5...10),
            color: colors.randomElement()!,
            isRound: Bool.random(),
            delay: Double.random(in: 0...0.3),
            lifetime: Double.random(in: 1.8...2.5)
        )
    }
}

struct ConfettiModifier: ViewModifier {
    let isActive: Bool
    @State private var showConfetti = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if showConfetti {
                    ConfettiView()
                        .transition(.opacity)
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    showConfetti = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { showConfetti = false }
                    }
                }
            }
    }
}

extension View {
    func confettiOnComplete(_ isActive: Bool) -> some View {
        modifier(ConfettiModifier(isActive: isActive))
    }
}
