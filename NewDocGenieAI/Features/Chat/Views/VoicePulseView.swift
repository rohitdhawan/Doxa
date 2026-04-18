import SwiftUI

struct VoicePulseView: View {
    let audioLevel: Float
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Outer pulse ring
            Circle()
                .fill(Color.appDanger.opacity(0.15))
                .frame(width: pulseSize, height: pulseSize)
                .scaleEffect(isPulsing ? 1.3 : 1.0)

            // Inner filled circle reactive to audio
            Circle()
                .fill(Color.appDanger)
                .frame(
                    width: 14 + CGFloat(audioLevel) * 6,
                    height: 14 + CGFloat(audioLevel) * 6
                )

            Image(systemName: "waveform")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: 32, height: 32)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }

    private var pulseSize: CGFloat {
        28 + CGFloat(audioLevel) * 8
    }
}
