import SwiftUI

struct FileListView: View {
    let files: [DocumentFile]
    let onSelect: (DocumentFile) -> Void
    let onAction: (DocumentFile, FileRowAction) -> Void

    var body: some View {
        if files.isEmpty {
            EmptyStateView(
                icon: "doc.on.doc",
                title: "No Files Yet",
                message: "Import documents to get started. Tap the + button to browse your files."
            )
            .frame(maxHeight: .infinity)
        } else {
            LazyVStack(spacing: 0) {
                ForEach(Array(files.enumerated()), id: \.element.id) { index, file in
                    Button {
                        onSelect(file)
                    } label: {
                        FileRowView(file: file) { action in
                            onAction(file, action)
                        }
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            HapticManager.medium()
                            onAction(file, .delete)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            HapticManager.light()
                            onAction(file, .share)
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            HapticManager.light()
                            onAction(file, .toggleFavorite)
                        } label: {
                            Label(
                                file.isFavorite ? "Unfavorite" : "Favorite",
                                systemImage: file.isFavorite ? "star.slash" : "star.fill"
                            )
                        }
                        .tint(.yellow)
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))

                    Divider()
                        .background(Color.appBorder)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: files.map(\.id))
        }
    }
}
