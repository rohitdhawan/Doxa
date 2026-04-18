import SwiftUI

struct ScanPageManagerSheet: View {
    @Bindable var viewModel: ScanReviewViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, page in
                    HStack(spacing: AppSpacing.md) {
                        Image(uiImage: page.currentImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))

                        Text("Page \(index + 1)")
                            .font(.appBody)
                            .foregroundStyle(Color.appText)

                        Spacer()

                        if viewModel.pages.count > 1 {
                            Button {
                                viewModel.deletePage(at: index)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(Color.appDanger)
                            }
                        }
                    }
                }
                .onMove { source, destination in
                    viewModel.movePage(from: source, to: destination)
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Manage Pages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
