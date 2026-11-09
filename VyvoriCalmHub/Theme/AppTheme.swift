import SwiftUI

enum AppTheme {
    static let background = Color("AppBackground")
    static let surface = Color("AppSurface")
    static let primary = Color("AppPrimary")
    static let accent = Color("AppAccent")

    /// Dark brown for titles and body on coral or cream.
    static let ink = Color(red: 0.16, green: 0.08, blue: 0.06)
    /// Muted brown for secondary copy — readable on cream (not system gray).
    static let inkMuted = Color(red: 0.36, green: 0.20, blue: 0.16)
    /// Deeper magenta for small labels on cream cards.
    static let accentInk = Color(red: 0.58, green: 0.05, blue: 0.46)
    /// Opaque warm cream so body text meets contrast on cards.
    static let card = Color(red: 1.0, green: 0.965, blue: 0.94)
    static let fieldFill = Color(red: 1.0, green: 0.99, blue: 0.97)

    static var trail: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.62, green: 0.08, blue: 0.50),
                Color(red: 0.78, green: 0.14, blue: 0.62),
                Color(red: 0.58, green: 0.06, blue: 0.46)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var stone: LinearGradient {
        LinearGradient(
            colors: [
                card,
                Color(red: 1.0, green: 0.94, blue: 0.90),
                card
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func display(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func stoneShape(_ cut: Int = 0) -> UnevenRoundedRectangle {
        switch cut % 3 {
        case 1:
            return UnevenRoundedRectangle(topLeadingRadius: 30, bottomLeadingRadius: 10, bottomTrailingRadius: 34, topTrailingRadius: 8, style: .continuous)
        case 2:
            return UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 26, bottomTrailingRadius: 12, topTrailingRadius: 36, style: .continuous)
        default:
            return UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 36, bottomTrailingRadius: 16, topTrailingRadius: 28, style: .continuous)
        }
    }
}

struct FootfallPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? 3 : 0)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

typealias SoftPressStyle = FootfallPressStyle
