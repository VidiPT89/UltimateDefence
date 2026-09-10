import SwiftUI

enum AppTheme: String, CaseIterable {
    case dark
    case light
    case system
}

final class ThemeManager: ObservableObject {
    @AppStorage("selectedTheme") var currentTheme: AppTheme = .dark {
        didSet { objectWillChange.send() }
    }

    var colorScheme: ColorScheme? {
        switch currentTheme {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }

    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
    }
}
