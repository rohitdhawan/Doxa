import SwiftUI

struct ProcessingBubbleView: View {
    let message: ChatMessage

    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0.8

    private var toolIcon: String {
        switch message.inlineToolType {
        case "ocr": return "text.viewfinder"
        case "summarize": return "doc.text.magnifyingglass"
        case "compress": return "arrow.down.doc"
        case "watermark": return "drop.triangle"
        default: return "gearshape.2"
        }
    }

    private var toolLabel: String {
        switch message.inlineToolType {
        case "ocr": return "OCR Engine"
        case "summarize": return "AI Summary"
        case "compress": return "Compressor"
        case "watermark": return "Watermark"
        default: return "Processing"
        }
    }

    var body: some View {
        HStack(alignment: .top) {
            // AI avatar
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.appPrimary)
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                // Badge
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "gearshape.2")
                        .font(.system(size: 10))
                    Text(toolLabel)
                        .font(.appMicro)
                }
                .foregroundStyle(Color.appPrimary)

                // Processing card
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack(spacing: AppSpacing.sm) {
                        // Pulsing icon with ring
                        ZStack {
                            Circle()
                                .stroke(Color.appPrimary.opacity(ringOpacity * 0.4), lineWidth: 2)
                                .frame(width: 44, height: 44)
                                .scaleEffect(ringScale)

                            GlowingIcon(systemName: toolIcon, color: .appPrimary, size: 18, bgSize: 34)
                        }
                        .frame(width: 48, height: 48)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(toolLabel)
                                .font(.appCaption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.appText)
                            Text(message.content)
                                .font(.appMicro)
                                .foregroundStyle(Color.appTextMuted)
                        }
                    }

                    // Shimmer skeleton lines
                    VStack(spacing: AppSpacing.xs) {
                        SkeletonView(height: 10)
                        SkeletonView(width: 180, height: 10)
                        SkeletonView(width: 120, height: 10)
                    }
                }
                .padding(AppSpacing.md)
                .glassCard(cornerRadius: AppCornerRadius.lg)
            }

            Spacer(minLength: 40)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                ringScale = 1.3
                ringOpacity = 0.0
            }
        }
    }
}
