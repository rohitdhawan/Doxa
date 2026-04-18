import SwiftUI

// MARK: - Adaptive Color Helper
private extension Color {
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }

    init(lightHex: UInt64, darkHex: UInt64) {
        self.init(light: Color(hex: lightHex), dark: Color(hex: darkHex))
    }

    init(hex: UInt64) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}

// MARK: - App Colors (Adaptive Dark/Light)
extension Color {
    // Primary & Accent
    static let appPrimary = Color(lightHex: 0x1E3A5F, darkHex: 0x4A90D9)
    static let appPrimaryLight = Color(lightHex: 0x2D5986, darkHex: 0x6BA3E0)
    static let appAccent = Color(lightHex: 0xC27803, darkHex: 0xF5A623)

    // Semantic
    static let appSuccess = Color(lightHex: 0x2D8A56, darkHex: 0x34D399)
    static let appWarning = Color(lightHex: 0xC27803, darkHex: 0xFBBF24)
    static let appDanger = Color(lightHex: 0xDC2626, darkHex: 0xF87171)

    // Backgrounds
    static let appBackground = Color(lightHex: 0xF8F9FA, darkHex: 0x0D1117)
    static let appBGCard = Color(lightHex: 0xFFFFFF, darkHex: 0x161B22)
    static let appBGElevated = Color(lightHex: 0xF0F1F3, darkHex: 0x1C2128)

    // Legacy alias so existing code using appBGDark still compiles
    static let appBGDark = appBackground

    // Text
    static let appText = Color(lightHex: 0x1A1A2E, darkHex: 0xE6EDF3)
    static let appTextMuted = Color(lightHex: 0x6B7280, darkHex: 0x8B949E)
    static let appTextDim = Color(lightHex: 0x9CA3AF, darkHex: 0x6E7681)

    // Border & Glass
    static let appBorder = Color(lightHex: 0xE5E7EB, darkHex: 0x30363D)
    static let appGlassStroke = Color(
        light: Color.black.opacity(0.08),
        dark: Color.white.opacity(0.12)
    )

    // Gradients
    static let appGradientPrimary = LinearGradient(
        colors: [appPrimary, appAccent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let appGradientAccent = LinearGradient(
        colors: [appAccent, appPrimary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let appGradientSuccess = LinearGradient(
        colors: [appSuccess, Color(lightHex: 0x10B981, darkHex: 0x6EE7B7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let appGradientDanger = LinearGradient(
        colors: [appDanger, Color(lightHex: 0xEF4444, darkHex: 0xFCA5A5)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension ShapeStyle where Self == Color {
    static var appPrimary: Color { Color.appPrimary }
    static var appAccent: Color { Color.appAccent }
}
