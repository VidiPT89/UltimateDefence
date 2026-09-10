import SwiftUI

@main
struct UltimateDefenceApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var languageManager = LanguageManager()
    @StateObject private var soundManager = SoundManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(themeManager)
                .environmentObject(languageManager)
                .environmentObject(soundManager)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
