import SwiftUI

struct GlowingIcon: View {
    let systemName: String
    var color: Color = .appPrimary
    var size: CGFloat = 24
    var bgSize: CGFloat = 44

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: .medium))
            .foregroundStyle(color)
            .frame(width: bgSize, height: bgSize)
            .background(color.opacity(0.15), in: Circle())
            .glow(color: color, radius: 8)
    }
}
