import SwiftUI

struct CompressionComparisonBar: View {
    let originalSize: Int64
    let compressedSize: Int64
    @State private var animatedRatio: CGFloat = 1.0

    private var ratio: CGFloat {
        guard originalSize > 0 else { return 1.0 }
        return CGFloat(compressedSize) / CGFloat(originalSize)
    }

    private var reductionPercent: Int {
        guard originalSize > 0 else { return 0 }
        return Int((originalSize - compressedSize) * 100 / originalSize)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text("Original")
                    .font(.appMicro)
                    .foregroundStyle(Color.appTextDim)
                Spacer()
                Text("\(reductionPercent)% smaller")
                    .font(.appMicro)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appAccent)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.appTextDim.opacity(0.15))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.appAccent, Color.appSuccess],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * animatedRatio, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(AppSpacing.sm)
        .background(Color.appBGDark.opacity(0.5), in: RoundedRectangle(cornerRadius: AppCornerRadius.sm))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    animatedRatio = ratio
                }
            }
        }
    }
}
