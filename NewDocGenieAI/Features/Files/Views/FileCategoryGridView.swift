import SwiftUI

struct FileCategoryGridView: View {
    let files: [DocumentFile]
    @Binding var selectedCategory: FileCategory
    let viewModel: FilesViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
            ForEach(FileCategory.allCases) { category in
                CategoryChip(
                    category: category,
                    count: viewModel.categoryCount(category, in: files),
                    isSelected: selectedCategory == category
                ) {
                    withAnimation(AppAnimations.springSmooth) {
                        selectedCategory = category
                    }
                }
            }
        }
        .padding(AppSpacing.sm)
        .glassCard(cornerRadius: AppCornerRadius.md)
    }
}
