import SwiftUI

struct FileRenameSheet: View {
    let file: DocumentFile
    let onRename: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var newName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("New Name") {
                    TextField("File name", text: $newName)
                        .font(.appBody)
                        .autocorrectionDisabled()
                }

                Section {
                    Text("Extension: .\(file.fileExtension)")
                        .font(.appCaption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Rename File")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onRename(newName)
                        dismiss()
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                newName = file.name
            }
        }
    }
}
