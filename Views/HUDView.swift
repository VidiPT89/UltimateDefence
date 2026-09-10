import SwiftUI

struct HUDView: View {
    @ObservedObject var session: GameSession

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(session.health < 35 ? 0.55 : 0.22)
                ],
                center: .center,
                startRadius: 220,
                endRadius: 640
            )
            .ignoresSafeArea()
            .animation(.easeOut(duration: 0.35), value: session.health)

            Color.red.opacity(session.health < 30 ? 0.08 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            crosshair

            VStack(spacing: 0) {
                topBar
                Spacer()
                if session.plantHint {
                    Text("Segura E para desarmar")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .tracking(1.2)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .foregroundStyle(UDTheme.ink)
                        .background(UDTheme.ember)
                        .clipShape(Capsule())
                        .shadow(color: UDTheme.ember.opacity(0.55), radius: 18, y: 6)
                }
                if session.defuseProgress > 0 {
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12)).frame(width: 280, height: 8)
                        Capsule()
                            .fill(UDTheme.ember)
                            .frame(width: 280 * session.defuseProgress, height: 8)
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                }
                bottomBar
            }
            .padding(22)
        }
        .allowsHitTesting(false)
    }

    private var crosshair: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                .frame(width: 38, height: 38)
            Capsule().fill(UDTheme.ember).frame(width: 12, height: 2)
            Capsule().fill(UDTheme.ember).frame(width: 2, height: 12)
            Circle().fill(Color.white).frame(width: 3, height: 3)
        }
        .scaleEffect(session.hitTick > 0 ? 1.18 : 1)
        .animation(.spring(response: 0.18, dampingFraction: 0.55), value: session.hitTick)
    }

    private var topBar: some View {
        HStack(spacing: 18) {
            HStack(spacing: 8) {
                Circle().fill(UDTheme.ember).frame(width: 7, height: 7)
                Text("\(session.attackersAlive) ATACANTES")
            }
            Spacer()
            Text(timerText)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(session.bombPlanted ? UDTheme.ember : Color.white)
                .shadow(color: session.bombPlanted ? UDTheme.ember.opacity(0.6) : .clear, radius: 12)
            Spacer()
            Text(session.bombPlanted ? "ARTEFACTO ARMADO" : "SITE A")
                .foregroundStyle(session.bombPlanted ? UDTheme.ember : UDTheme.mint)
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .tracking(1.4)
        .foregroundStyle(UDTheme.steel)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var bottomBar: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Text("VIDA")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(UDTheme.steel)
                Text("\(session.health)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(session.health < 30 ? Color.red : Color.white)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12)).frame(width: 160, height: 6)
                    Capsule()
                        .fill(session.health < 30 ? Color.red : UDTheme.ember)
                        .frame(width: 160 * CGFloat(session.health) / 100, height: 6)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(session.weaponName.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(UDTheme.steel)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(session.mag)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("/ \(session.reserve)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(UDTheme.steel)
                }
                if session.reloading {
                    Text("A RECARREGAR")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(UDTheme.amber)
                        .transition(.opacity)
                }
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var timerText: String {
        let t = Int(session.timeLeft.rounded(.down))
        return String(format: "%d:%02d", t / 60, t % 60)
    }
}
