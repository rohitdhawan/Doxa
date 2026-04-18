import UIKit

@MainActor
enum HapticManager {
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private static let notificationGenerator = UINotificationFeedbackGenerator()
    private static let selectionGenerator = UISelectionFeedbackGenerator()

    static func light() {
        lightGenerator.impactOccurred()
    }

    static func medium() {
        mediumGenerator.impactOccurred()
    }

    static func heavy() {
        heavyGenerator.impactOccurred()
    }

    static func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    static func error() {
        notificationGenerator.notificationOccurred(.error)
    }

    static func selection() {
        selectionGenerator.selectionChanged()
    }
}
