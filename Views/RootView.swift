import SwiftUI

struct RootView: View {
    @StateObject private var session = GameSession()
    @State private var world: GameWorld?

    var body: some View {
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
        .frame(minWidth: 1100, minHeight: 700)
        .background(Color.black)
        .animation(.easeOut(duration: 0.35), value: session.screen)
        .onDisappear {
            session.capturedMouse = false
        }
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
