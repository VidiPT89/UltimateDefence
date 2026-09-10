import SwiftUI

enum AppLanguage: String, CaseIterable {
    case portuguese = "pt-PT"
    case english = "en"

    var displayName: String {
        switch self {
        case .portuguese: return "Português (PT)"
        case .english: return "English"
        }
    }
}

final class LanguageManager: ObservableObject {
    @AppStorage("selectedLanguage") var currentLanguage: AppLanguage = .portuguese {
        didSet { objectWillChange.send() }
    }

    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }

    func t(_ key: L10nKey) -> String {
        L10n.string(key, language: currentLanguage)
    }
}
