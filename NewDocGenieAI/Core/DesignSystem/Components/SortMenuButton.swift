import SwiftUI

struct SortMenuButton: View {
    @Binding var selectedSort: FileSortOption

    var body: some View {
        Menu {
            ForEach(FileSortOption.allCases) { option in
                Button {
                    selectedSort = option
                } label: {
                    HStack {
                        Text(option.rawValue)
                        if selectedSort == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "arrow.up.arrow.down")
                Text("Sort")
            }
            .font(.appCaption)
            .foregroundStyle(Color.appTextMuted)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(Color.appBGCard, in: RoundedRectangle(cornerRadius: AppCornerRadius.sm))
        }
    }
}
