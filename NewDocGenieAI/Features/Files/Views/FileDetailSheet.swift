import SwiftUI

struct FileDetailSheet: View {
    let file: DocumentFile
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("File") {
                    DetailRow(label: "Name", value: file.fullFileName)
                    DetailRow(label: "Type", value: file.fileExtension.uppercased())
                    DetailRow(label: "Size", value: file.fileSize.formattedFileSize)
                    if let pages = file.pageCount {
                        DetailRow(label: "Pages", value: "\(pages)")
                    }
                }

                Section("Dates") {
                    DetailRow(label: "Imported", value: file.importedAt.relativeDisplay)
                    if let created = file.originalCreatedAt {
                        DetailRow(label: "Created", value: created.relativeDisplay)
                    }
                    if let modified = file.originalModifiedAt {
                        DetailRow(label: "Modified", value: modified.relativeDisplay)
                    }
                    if let opened = file.lastOpenedAt {
                        DetailRow(label: "Last Opened", value: opened.relativeDisplay)
                    }
                }

                Section("Location") {
                    DetailRow(label: "Path", value: file.relativeFilePath)
                }
            }
            .navigationTitle("File Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
        .font(.appBody)
    }
}
