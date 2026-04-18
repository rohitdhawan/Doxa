import SwiftUI

struct PDFThumbnailGridView: View {
    let thumbnails: [UIImage]
    let currentPage: Int
    let onPageSelected: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.md), count: 3)

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                        ForEach(Array(thumbnails.enumerated()), id: \.offset) { index, thumbnail in
                            Button {
                                HapticManager.light()
                                onPageSelected(index + 1)
                                dismiss()
                            } label: {
                                VStack(spacing: AppSpacing.xs) {
                                    Image(uiImage: thumbnail)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 160)
                                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                                                .stroke(
                                                    (index + 1) == currentPage ? Color.appPrimary : Color.appBorder,
                                                    lineWidth: (index + 1) == currentPage ? 3 : 1
                                                )
                                        )
                                        .shadow(
                                            color: (index + 1) == currentPage ? Color.appPrimary.opacity(0.3) : .clear,
                                            radius: 8
                                        )

                                    Text("\(index + 1)")
                                        .font(.appCaption)
                                        .fontWeight((index + 1) == currentPage ? .bold : .regular)
                                        .foregroundStyle(
                                            (index + 1) == currentPage ? Color.appPrimary : Color.appTextMuted
                                        )
                                }
                            }
                            .buttonStyle(.plain)
                            .id(index)
                        }
                    }
                    .padding(AppSpacing.md)
                }
                .onAppear {
                    if currentPage > 0 {
                        proxy.scrollTo(currentPage - 1, anchor: .center)
                    }
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Pages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.appPrimary)
                }
            }
        }
    }
}
