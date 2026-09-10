import SwiftUI

enum UDTheme {
    static let orange = Color("PrimaryOrange")
    static let burnt = Color("BurntYellow")
    static let ink = Color("Black")

    static func pageBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? ink : Color(red: 0.98, green: 0.96, blue: 0.90)
    }

    static func cardFill(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.72)
    }

    static func muted(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.72) : ink.opacity(0.65)
    }

    static func primaryText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white : ink
    }
}
