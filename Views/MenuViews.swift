import SwiftUI

struct MainMenuView: View {
    let onPlay: () -> Void
    @State private var pulse = false

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                UDTheme.ink.ignoresSafeArea()
                animatedBackdrop(t)
                VStack(spacing: 28) {
                    Spacer()
                    Text("ULTIMATE DEFENCE")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(.white)
                        .shadow(color: UDTheme.ember.opacity(0.55), radius: pulse ? 28 : 10)
                    Text("Defende o site A. Elimina os atacantes ou impede o artefacto.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(UDTheme.steel)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 480)

                    VStack(alignment: .leading, spacing: 8) {
                        controlRow("WASD", "Mover")
                        controlRow("Rato + clique", "Olhar e disparar")
                        controlRow("1 / 2 · R · E", "Armas, recarregar, desarmar")
                        controlRow("Esc", "Menu")
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    )

                    Button(action: onPlay) {
                        HStack(spacing: 10) {
                            Text("INICIAR RONDA")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .tracking(1.4)
                            Image(systemName: "play.fill")
                                .font(.system(size: 12, weight: .bold))
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Color.black.opacity(0.18)))
                        }
                        .padding(.leading, 26)
                        .padding(.trailing, 10)
                        .padding(.vertical, 10)
                        .foregroundStyle(UDTheme.ink)
                        .background(UDTheme.ember)
                        .clipShape(Capsule())
                        .shadow(color: UDTheme.ember.opacity(0.45), radius: 16, y: 8)
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(pulse ? 1.03 : 1)
                    Spacer()
                }
                .padding(48)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
    }

    private func animatedBackdrop(_ t: TimeInterval) -> some View {
        ZStack {
            RadialGradient(
                colors: [UDTheme.ember.opacity(0.28), Color.clear],
                center: UnitPoint(x: 0.5 + 0.08 * sin(t * 0.4), y: 0.35),
                startRadius: 20,
                endRadius: 520
            )
            RadialGradient(
                colors: [UDTheme.amber.opacity(0.12), Color.clear],
                center: UnitPoint(x: 0.72, y: 0.8),
                startRadius: 10,
                endRadius: 420
            )
            ForEach(0..<18, id: \.self) { i in
                Capsule()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 1, height: 90 + CGFloat(i % 5) * 18)
                    .offset(
                        x: CGFloat((i - 9) * 48),
                        y: CGFloat(sin(t * 0.7 + Double(i)) * 24)
                    )
            }
        }
        .ignoresSafeArea()
    }

    private func controlRow(_ keys: String, _ label: String) -> some View {
        HStack {
            Text(keys)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(UDTheme.ember)
                .frame(width: 140, alignment: .leading)
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(UDTheme.steel)
        }
    }
}

struct ResultView: View {
    @ObservedObject var session: GameSession
    let onAgain: () -> Void
    let onMenu: () -> Void

    private var victory: Bool {
        switch session.outcome {
        case .defendersWinElimination, .defendersWinTime, .defendersWinDefuse: return true
        default: return false
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea()
            VStack(spacing: 22) {
                Text(victory ? "OBJECTIVO CUMPRIDO" : "LINHA QUEBRADA")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(victory ? UDTheme.mint : UDTheme.ember)
                Text(session.resultTitle)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                HStack(spacing: 14) {
                    Button("Nova ronda", action: onAgain)
                    Button("Menu", action: onMenu)
                }
                .buttonStyle(.plain)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
            }
            .padding(36)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: (victory ? UDTheme.mint : UDTheme.ember).opacity(0.25), radius: 30)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}
