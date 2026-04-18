import SwiftUI
import SwiftData

struct DocumentCardBubbleView: View {
    let message: ChatMessage
    var onAction: ((ChatAction) -> Void)?
    @Query private var documents: [DocumentFile]

    init(message: ChatMessage, onAction: ((ChatAction) -> Void)? = nil) {
        self.message = message
        self.onAction = onAction
        _documents = Query(sort: \DocumentFile.importedAt)
    }

    private var document: DocumentFile? {
        documents.first { $0.id.uuidString == message.documentFileId }
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

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // Badge
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: badgeIcon)
                        .font(.system(size: 10))
                    Text(badgeLabel)
                        .font(.appMicro)
                }
                .foregroundStyle(Color.appPrimary)

                // Document Card
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack(spacing: AppSpacing.sm) {
                        // Thumbnail: multi-page strip or single
                        if let pageCount = document?.pageCount, pageCount > 1 {
                            ScanPageThumbnailStrip(
                                documentFileId: message.documentFileId,
                                pageCount: pageCount
                            )
                        } else {
                            PDFThumbnailView(documentFileId: message.documentFileId)
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(message.content)
                                .font(.appBody)
                                .foregroundStyle(Color.appText)

                            // File metadata
                            if !message.documentFileId.isEmpty {
                                DocumentMetadataRow(documentFileId: message.documentFileId)
                            }
                        }
                    }

                    // Action chips with icons
                    let actions = message.actions
                    if !actions.isEmpty {
                        FlowLayout(spacing: AppSpacing.sm) {
                            ForEach(actions) { action in
                                Button {
                                    HapticManager.light()
                                    onAction?(action)
                                } label: {
                                    HStack(spacing: AppSpacing.xs) {
                                        Image(systemName: action.icon)
                                            .font(.system(size: 12, weight: .semibold))
                                        Text(action.label)
                                            .font(.appCaption)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundStyle(Color.appPrimary)
                                    .padding(.horizontal, AppSpacing.md)
                                    .padding(.vertical, AppSpacing.sm)
                                    .background(Color.appPrimary.opacity(0.1), in: Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.appPrimary.opacity(0.25), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.scale)
                            }
                        }
                    }
                }
                .padding(AppSpacing.md)
                .glassCard(cornerRadius: AppCornerRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                        .stroke(
                            LinearGradient(
                                colors: [Color.appPrimary.opacity(0.6), Color.appAccent.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .glow(color: .appPrimary, radius: 6)
            }

            Spacer(minLength: 20)
        }
    }

    private var badgeIcon: String {
        message.toolBadge == "Scanner" ? "doc.viewfinder" : "doc.badge.arrow.up"
    }

    private var badgeLabel: String {
        message.toolBadge ?? "Document"
    }
}
