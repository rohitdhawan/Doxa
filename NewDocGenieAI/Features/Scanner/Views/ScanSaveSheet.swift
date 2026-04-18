import SwiftUI

struct ScanSaveSheet: View {
    @Bindable var viewModel: ScanReviewViewModel
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("File Name") {
                    TextField("Document name", text: $viewModel.fileName)
                        .font(.appBody)
                        .autocorrectionDisabled()
                }

                Section {
                    HStack {
                        Text("Pages")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(viewModel.pages.count)")
                    }
                    HStack {
                        Text("Format")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("PDF")
                    }
                }
                .font(.appBody)
            }
            .navigationTitle("Save Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            onSave()
                        }
                        .disabled(viewModel.fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }
}
