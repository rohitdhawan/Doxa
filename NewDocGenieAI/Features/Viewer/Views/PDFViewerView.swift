import SwiftUI

struct PDFViewerView: View {
    let url: URL
    let fileName: String
    @State private var currentPage = 0
    @State private var totalPages = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            PDFKitView(url: url, currentPage: $currentPage, totalPages: $totalPages)
                .ignoresSafeArea(edges: .bottom)

            if totalPages > 0 {
                Text("Page \(currentPage) of \(totalPages)")
                    .font(.appCaption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.xs)
                    .background(.black.opacity(0.6), in: Capsule())
                    .padding(.bottom, AppSpacing.md)
            }
        }
        .navigationTitle(fileName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBGDark, for: .navigationBar)
    }
}
