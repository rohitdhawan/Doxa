import SwiftUI

struct AttachmentPreviewStrip: View {
    let attachment: PendingAttachment
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: attachment.iconSystemName)
                .font(.system(size: 16))
                .foregroundStyle(Color.appPrimary)
                .frame(width: 32, height: 32)
                .background(Color.appPrimary.opacity(0.1), in: RoundedRectangle(cornerRadius: AppCornerRadius.sm))

            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.fileName)
                    .font(.appCaption)
                    .foregroundStyle(Color.appText)
                    .lineLimit(1)
                Text(attachment.fileExtension.uppercased())
                    .font(.appMicro)
                    .foregroundStyle(Color.appTextMuted)
            }

            Spacer()

            Button {
                HapticManager.light()
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.appTextDim)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .glassCard(cornerRadius: AppCornerRadius.md)
        .padding(.horizontal, AppSpacing.md)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
