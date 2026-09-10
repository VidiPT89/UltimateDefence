import SwiftUI

struct RootView: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var sounds: SoundManager
    @StateObject private var session = GameSession()
    @State private var world: GameWorld?
    @State private var roundToken = 0
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
                    .id(roundToken)
                    .ignoresSafeArea()
                HUDView(session: session)
            }
            if session.screen == .menu {
                MainMenuView(session: session, onPlay: startRound)
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
        session.capturedMouse = false
        roundToken += 1
        world = GameWorld(session: session, sounds: sounds)
        session.screen = .playing
        session.outcome = .inProgress
        session.capturedMouse = true
    }
}
