import SwiftUI

struct ScanFilterBar: View {
    let selectedFilter: ScanFilter
    let onFilterSelect: (ScanFilter) -> Void

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(ScanFilter.allCases) { filter in
                Button {
                    onFilterSelect(filter)
                } label: {
                    VStack(spacing: AppSpacing.xs) {
                        Image(systemName: filter.systemImage)
                            .font(.system(size: 18))
                        Text(filter.rawValue)
                            .font(.appMicro)
                    }
                    .foregroundStyle(
                        selectedFilter == filter ? Color.appPrimary : Color.appTextMuted
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        selectedFilter == filter ? Color.appPrimary.opacity(0.1) : Color.clear,
                        in: RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}
