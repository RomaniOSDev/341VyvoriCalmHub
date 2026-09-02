import SwiftUI

enum AppTheme {
    static let background = Color("AppBackground")
    static let surface = Color("AppSurface")
    static let primary = Color("AppPrimary")
    static let accent = Color("AppAccent")

    static var trail: LinearGradient {
        LinearGradient(
            colors: [primary, accent.opacity(0.85), primary.opacity(0.7)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var stone: LinearGradient {
        LinearGradient(
            colors: [surface.opacity(0.97), background.opacity(0.55), surface.opacity(0.9)],
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
