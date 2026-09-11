import SwiftUI

struct HUDView: View {
    @ObservedObject var session: GameSession
    @EnvironmentObject private var language: LanguageManager
    @State private var hurtFlash = 0.0

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    Color.clear,
                    Color("Black").opacity(session.health < 35 ? 0.55 : 0.22)
                ],
                center: .center,
                startRadius: 220,
                endRadius: 640
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .animation(.easeOut(duration: 0.35), value: session.health)

            Color.red.opacity(max(session.health < 30 ? 0.10 : 0, hurtFlash))
                .ignoresSafeArea()
                .allowsHitTesting(false)

            crosshair
                .allowsHitTesting(false)

            if session.freezeLeft > 0.05 {
                VStack(spacing: 6) {
                    Text(language.t(.freeze).uppercased())
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .tracking(2)
                    Text("\(Int(session.freezeLeft.rounded(.up)))")
                        .font(.system(size: 56, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 18)
                .background(Color.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    radar
                    Spacer()
                    killFeed
                }
                topBar
                Spacer()
                if !session.capturedMouse {
                    Text(language.t(.clickToCapture))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color("Black"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(UDTheme.burnt)
                        .clipShape(Capsule())
                        .padding(.bottom, 10)
                }
                if session.plantHint {
                    Text(language.t(.holdDefuse))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .tracking(1.0)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .foregroundStyle(Color("Black"))
                        .background(UDTheme.orange)
                        .clipShape(Capsule())
                        .shadow(color: UDTheme.orange.opacity(0.55), radius: 18, y: 6)
                }
                if session.defuseProgress > 0 {
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12)).frame(width: 280, height: 8)
                        Capsule()
                            .fill(UDTheme.orange)
                            .frame(width: 280 * session.defuseProgress, height: 8)
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                }
                bottomBar
            }
            .padding(22)
            .allowsHitTesting(false)
        }
        .allowsHitTesting(false)
        .onChange(of: session.damageTick) { _ in
            guard session.damageTick > 0 else { return }
            hurtFlash = 0.34
            withAnimation(.easeOut(duration: 0.4)) {
                hurtFlash = 0
            }
        }
    }

    private var radar: some View {
        let size: CGFloat = 128
        return ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black.opacity(0.55))
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(UDTheme.orange.opacity(0.45), lineWidth: 1)
            ForEach(session.radarBlips) { blip in
                let point = radarPoint(blip.x, blip.z, size: size)
                blipMark(blip.kind)
                    .position(point)
            }
        }
        .frame(width: size, height: size)
        .clipped()
    }

    private func blipMark(_ kind: RadarBlip.Kind) -> some View {
        let color: Color = {
            switch kind {
            case .player: return UDTheme.orange
            case .ally: return Color.cyan
            case .enemy: return Color.red
            case .site: return UDTheme.burnt
            case .bomb: return Color.orange
            }
        }()
        let side: CGFloat = kind == .player ? 7 : (kind == .site || kind == .bomb ? 6 : 5)
        return Circle()
            .fill(color)
            .frame(width: side, height: side)
            .overlay(Circle().stroke(Color.white.opacity(kind == .player ? 0.9 : 0.25), lineWidth: 1))
    }

    private func radarPoint(_ x: Float, _ z: Float, size: CGFloat) -> CGPoint {
        let dx = x - session.radarMe.x
        let dz = z - session.radarMe.z
        let yaw = session.radarYaw
        let c = cos(-yaw)
        let s = sin(-yaw)
        let rx = dx * c - dz * s
        let rz = dx * s + dz * c
        let scale = (size - 18) / CGFloat(max(session.radarSpan, 40))
        return CGPoint(
            x: size / 2 + CGFloat(rx) * scale,
            y: size / 2 - CGFloat(rz) * scale
        )
    }

    private var killFeed: some View {
        VStack(alignment: .trailing, spacing: 4) {
            ForEach(session.killFeed) { line in
                Text("\(sideName(line.killer))  \(sideName(line.victim))")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.45), in: Capsule())
            }
        }
        .frame(minWidth: 120, alignment: .trailing)
    }

    private func sideName(_ side: CombatSide) -> String {
        switch side {
        case .you: return language.t(.you)
        case .ct: return language.t(.defenderShort)
        case .t: return language.t(.terroristShort)
        }
    }

    private var crosshair: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                .frame(width: 38, height: 38)
            Capsule().fill(UDTheme.orange).frame(width: 12, height: 2)
            Capsule().fill(UDTheme.orange).frame(width: 2, height: 12)
            Circle().fill(Color.white).frame(width: 3, height: 3)
        }
        .scaleEffect(crosshairScale)
        .animation(.spring(response: 0.18, dampingFraction: 0.55), value: session.hitTick)
        .animation(.easeOut(duration: 0.12), value: session.moving)
        .animation(.easeOut(duration: 0.12), value: session.aiming)
    }

    private var crosshairScale: CGFloat {
        var scale: CGFloat = session.hitTick > 0 ? 1.18 : 1
        if session.aiming { scale *= 0.72 }
        if session.moving { scale *= 1.22 }
        return scale
    }

    private var topBar: some View {
        HStack(spacing: 18) {
            HStack(spacing: 8) {
                Circle().fill(UDTheme.orange).frame(width: 7, height: 7)
                Text("\(session.attackersAlive) \(language.t(.attackers).uppercased())")
            }
            Text("\(session.defendersAlive) \(language.t(.teammates).uppercased())")
            Text("\(session.kills) \(language.t(.kills).uppercased())")
                .foregroundStyle(UDTheme.burnt)
            Spacer()
            Text(timerText)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(session.bombPlanted ? UDTheme.orange : Color.white)
                .shadow(color: session.bombPlanted ? UDTheme.orange.opacity(0.6) : .clear, radius: 12)
            Spacer()
            Text(session.bombPlanted ? language.t(.artefactArmed).uppercased() : language.t(.defendSite).uppercased())
                .foregroundStyle(session.bombPlanted ? UDTheme.orange : UDTheme.burnt)
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .tracking(1.2)
        .foregroundStyle(Color.white.opacity(0.82))
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(UDTheme.orange.opacity(0.25), lineWidth: 1)
        )
    }

    private var bottomBar: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Text(language.t(.health).uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(Color.white.opacity(0.7))
                Text("\(session.health)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(session.health < 30 ? Color.red : Color.white)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12)).frame(width: 160, height: 6)
                    Capsule()
                        .fill(session.health < 30 ? Color.red : UDTheme.orange)
                        .frame(width: 160 * CGFloat(session.health) / 100, height: 6)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(weaponLabel.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(Color.white.opacity(0.7))
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(session.mag)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("/ \(session.reserve)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                if session.reloading {
                    Text(language.t(.reloading).uppercased())
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(UDTheme.burnt)
                }
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(UDTheme.orange.opacity(0.25), lineWidth: 1)
        )
    }

    private var weaponLabel: String {
        session.slot == .rifle ? language.t(.carbine) : language.t(.pistol)
    }

    private var timerText: String {
        let t = Int(session.timeLeft.rounded(.down))
        return String(format: "%d:%02d", t / 60, t % 60)
    }
}
