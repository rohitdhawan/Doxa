import SwiftUI

struct ChatActionButtonsView: View {
    let actions: [ChatAction]
    let onAction: (ChatAction) -> Void

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(actions) { action in
                Button {
                    HapticManager.light()
                    onAction(action)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: action.icon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(action.label)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Color.appAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.appAccent.opacity(0.12), in: Capsule())
                    .overlay(Capsule().stroke(Color.appAccent.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.scale)
                .accessibilityLabel(action.label)
                .accessibilityHint("Double tap to activate")
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}
