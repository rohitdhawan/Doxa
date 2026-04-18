import SwiftUI

struct FileActionsMenu: View {
    let file: DocumentFile
    let onAction: (FileRowAction) -> Void

    var body: some View {
        Menu {
            Button {
                onAction(.rename)
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Button {
                onAction(.toggleFavorite)
            } label: {
                Label(
                    file.isFavorite ? "Remove Favorite" : "Add to Favorites",
                    systemImage: file.isFavorite ? "star.slash" : "star"
                )
            }

            Button {
                onAction(.share)
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            Button {
                onAction(.info)
            } label: {
                Label("Info", systemImage: "info.circle")
            }

            Divider()

            Button(role: .destructive) {
                onAction(.delete)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.appBody)
                .foregroundStyle(Color.appTextMuted)
                .frame(width: 32, height: 32)
        }
        .accessibilityLabel("File actions for \(file.fullFileName)")
        .accessibilityHint("Double tap for rename, share, delete, and more")
    }
}
