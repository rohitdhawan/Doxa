import SwiftUI

struct TransferTabPlaceholder: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.appSuccess)

                Text("File Transfer")
                    .font(.appH2)
                    .foregroundStyle(Color.appText)

                Text("Transfer files between devices.\nComing soon.")
                    .font(.appBody)
                    .foregroundStyle(Color.appTextMuted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBGDark)
            .navigationTitle("Transfer")
        }
    }
}
