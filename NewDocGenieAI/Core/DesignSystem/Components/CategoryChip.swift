import SwiftUI

struct CategoryChip: View {
    let category: FileCategory
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.selection()
            action()
        }) {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: category.systemImage)
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? Color.appPrimary : Color.appTextMuted)

                Text(category.label)
                    .font(.appMicro)
                    .foregroundStyle(isSelected ? Color.appText : Color.appTextMuted)

                Text("\(count)")
                    .font(.appMicro)
                    .foregroundStyle(isSelected ? Color.appPrimary : Color.appTextDim)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                    .fill(isSelected ? Color.appPrimary.opacity(0.1) : Color.appBGCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                    .stroke(isSelected ? Color.appPrimary.opacity(0.4) : Color.appBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.scale)
        .animation(AppAnimations.springSmooth, value: isSelected)
        .accessibilityLabel("\(category.label), \(count) files")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Double tap to filter by \(category.label)")
    }
}
