import SwiftUI

struct ScanPageStripView: View {
    let pages: [ScannedPage]
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        Button {
                            onSelect(index)
                        } label: {
                            Image(uiImage: page.currentImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 56, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                                        .stroke(
                                            index == selectedIndex ? Color.appPrimary : Color.appBorder,
                                            lineWidth: index == selectedIndex ? 2 : 1
                                        )
                                )
                        }
                        .id(page.id)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
            .frame(height: 80)
            .onChange(of: selectedIndex) { _, newIndex in
                guard pages.indices.contains(newIndex) else { return }
                withAnimation {
                    proxy.scrollTo(pages[newIndex].id, anchor: .center)
                }
            }
        }
    }
}
