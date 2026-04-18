import SwiftUI

struct ScanPagePreview: View {
    let page: ScannedPage?

    var body: some View {
        if let page {
            Image(uiImage: page.currentImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                .padding(AppSpacing.md)
        } else {
            Color.appBGDark
        }
    }
}
