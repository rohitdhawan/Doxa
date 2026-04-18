import SwiftUI

struct SkeletonView: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var cornerRadius: CGFloat = AppCornerRadius.sm

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.appBGCard)
            .frame(width: width, height: height)
            .shimmer()
    }
}

struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            SkeletonView(width: 40, height: 40, cornerRadius: 10)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                SkeletonView(height: 14)
                SkeletonView(width: 120, height: 10)
            }
        }
        .padding(AppSpacing.md)
        .background(Color.appBGCard, in: RoundedRectangle(cornerRadius: AppCornerRadius.md))
    }
}

struct SkeletonList: View {
    var count: Int = 5

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(0..<count, id: \.self) { _ in
                SkeletonRow()
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }
}
