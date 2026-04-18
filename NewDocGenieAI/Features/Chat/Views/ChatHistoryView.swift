import SwiftUI

struct ChatHistoryView: View {
    let conversations: [Conversation]
    let onSelect: (Conversation) -> Void
    let onDelete: (Conversation) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if conversations.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "No Conversations",
                        message: "Start a new chat to see your history here."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppSpacing.sm) {
                            ForEach(Array(conversations.enumerated()), id: \.element.id) { index, conversation in
                                Button {
                                    HapticManager.selection()
                                    onSelect(conversation)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                            Text(conversation.title)
                                                .font(.appBody)
                                                .foregroundStyle(Color.appText)
                                                .lineLimit(1)

                                            Text(conversation.updatedAt.relativeDisplay)
                                                .font(.appCaption)
                                                .foregroundStyle(Color.appTextDim)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.appCaption)
                                            .foregroundStyle(Color.appTextDim)
                                    }
                                    .padding(AppSpacing.md)
                                    .glassCard(cornerRadius: AppCornerRadius.md)
                                }
                                .buttonStyle(.scale)
                                .staggeredAppear(index: index)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        HapticManager.medium()
                                        onDelete(conversation)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        onDelete(conversation)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(AppSpacing.md)
                    }
                }
            }
            .background(Color.appBGDark)
            .navigationTitle("Chat History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBGDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
