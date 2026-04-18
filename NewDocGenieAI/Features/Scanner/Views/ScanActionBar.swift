import SwiftUI

struct ScanActionBar: View {
    let onRotate: () -> Void
    let onDelete: () -> Void
    let onReorder: () -> Void
    let canDelete: Bool

    var body: some View {
        HStack(spacing: AppSpacing.xl) {
            ActionBarButton(icon: "rotate.right", label: "Rotate") {
                HapticManager.light()
                onRotate()
            }

            ActionBarButton(icon: "trash", label: "Delete") {
                HapticManager.medium()
                onDelete()
            }
            .disabled(!canDelete)
            .opacity(canDelete ? 1.0 : 0.4)

            ActionBarButton(icon: "rectangle.2.swap", label: "Reorder") {
                HapticManager.light()
                onReorder()
            }
        }
        .padding(.vertical, AppSpacing.md)
        .padding(.horizontal, AppSpacing.lg)
        .background(.ultraThinMaterial)
    }
}

private struct ActionBarButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.appMicro)
            }
            .foregroundStyle(Color.appTextMuted)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.scale)
        .accessibilityLabel(label)
    }
}
