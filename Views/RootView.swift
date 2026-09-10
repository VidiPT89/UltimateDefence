import SwiftUI

struct RootView: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var language: LanguageManager
    @StateObject private var session = GameSession()
    @State private var world: GameWorld?
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView {
                    withAnimation(.easeOut(duration: 0.45)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
            } else {
                gameRoot
                    .transition(.opacity)
            }
        }
        .frame(minWidth: 1100, minHeight: 700)
        .preferredColorScheme(theme.colorScheme)
        .animation(.easeOut(duration: 0.35), value: session.screen)
        .onDisappear {
            session.capturedMouse = false
        }
    }

    private var gameRoot: some View {
        ZStack {
            if let world, session.screen != .menu {
                GameSceneView(world: world, session: session)
                    .ignoresSafeArea()
                HUDView(session: session)
            }
            if session.screen == .menu {
                MainMenuView(onPlay: startRound)
            }
            if session.screen == .result {
                ResultView(
                    session: session,
                    onAgain: startRound,
                    onMenu: { session.screen = .menu }
                )
            }
        }
        .background(Color("Black"))
    }

    private func startRound() {
        if world == nil {
            world = GameWorld(session: session)
        } else {
            world?.resetRound()
        }
        session.screen = .playing
        session.capturedMouse = true
    }
}
