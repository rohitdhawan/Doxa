import SwiftUI

struct QuickLookViewerView: View {
    let url: URL
    let fileName: String

    var body: some View {
        QuickLookPreview(url: url)
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle(fileName)
            .navigationBarTitleDisplayMode(.inline)
    }
}
