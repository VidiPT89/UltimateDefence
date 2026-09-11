import SwiftUI

struct MainMenuView: View {
    @ObservedObject var session: GameSession
    let onPlay: () -> Void
    @EnvironmentObject private var language: LanguageManager
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var sounds: SoundManager
    @Environment(\.colorScheme) private var scheme
    @State private var pulse = false

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                UDTheme.pageBackground(for: scheme).ignoresSafeArea()
                animatedBackdrop(t)
                VStack(spacing: 22) {
                    Spacer()
                    Text(language.t(.appName).uppercased())
                        .font(.system(size: 46, weight: .heavy, design: .rounded))
                        .tracking(2.4)
                        .foregroundStyle(UDTheme.primaryText(for: scheme))
                        .shadow(color: UDTheme.orange.opacity(scheme == .dark ? 0.5 : 0.2), radius: pulse ? 24 : 8)
                    Text(language.t(.tagline))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(UDTheme.muted(for: scheme))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 480)

                    settingsCard
                    controlsCard

                    Button(action: onPlay) {
                        HStack(spacing: 10) {
                            Text(language.t(.startRound).uppercased())
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .tracking(1.2)
                            Image(systemName: "play.fill")
                                .font(.system(size: 11, weight: .bold))
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Color("Black").opacity(0.16)))
                        }
                        .padding(.leading, 24)
                        .padding(.trailing, 10)
                        .padding(.vertical, 10)
                        .foregroundStyle(Color("Black"))
                        .background(UDTheme.orange)
                        .clipShape(Capsule())
                        .shadow(color: UDTheme.orange.opacity(0.4), radius: 14, y: 6)
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(pulse ? 1.03 : 1)
                    Spacer()
                }
                .padding(44)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(language.t(.settings))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(UDTheme.muted(for: scheme))
            Picker(language.t(.language), selection: Binding(
                get: { language.currentLanguage },
                set: { language.setLanguage($0) }
            )) {
                ForEach(AppLanguage.allCases, id: \.self) { lang in
                    Text(lang.displayName).tag(lang)
                }
            }
            .pickerStyle(.segmented)

            Picker(language.t(.theme), selection: Binding(
                get: { theme.currentTheme },
                set: { theme.setTheme($0) }
            )) {
                Text(language.t(.darkMode)).tag(AppTheme.dark)
                Text(language.t(.lightMode)).tag(AppTheme.light)
                Text(language.t(.systemMode)).tag(AppTheme.system)
            }
            .pickerStyle(.segmented)

            Toggle(language.t(.sound), isOn: Binding(
                get: { sounds.soundEnabled },
                set: { sounds.setEnabled($0) }
            ))
            Picker(language.t(.map), selection: $session.arena) {
                Text(language.t(.dust2)).tag(ArenaMap.dust2)
                Text(language.t(.aztec)).tag(ArenaMap.aztec)
                Text(language.t(.office)).tag(ArenaMap.office)
                Text(language.t(.mill)).tag(ArenaMap.mill)
            }
            .pickerStyle(.segmented)
            Text(language.t(.match))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(UDTheme.muted(for: scheme))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(MatchSize.allCases) { size in
                    Button {
                        session.matchSize = size
                    } label: {
                        Text(size.label)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .foregroundStyle(session.matchSize == size ? Color("Black") : UDTheme.primaryText(for: scheme))
                            .background(session.matchSize == size ? UDTheme.orange : UDTheme.cardFill(for: scheme))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            Text(language.t(.difficulty))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(UDTheme.muted(for: scheme))
            Picker(language.t(.difficulty), selection: $session.difficulty) {
                Text(language.t(.easy)).tag(Difficulty.easy)
                Text(language.t(.normal)).tag(Difficulty.normal)
                Text(language.t(.hard)).tag(Difficulty.hard)
            }
            .pickerStyle(.segmented)
        }
        .padding(18)
        .frame(maxWidth: 520)
        .background(cardBackground)
    }

    private var controlsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            controlRow("WASD", language.t(.move))
            controlRow(language.t(.sprintJump), language.t(.sprintJumpHint))
            controlRow(language.t(.mouseLook), language.t(.lookShoot))
            controlRow(language.t(.aim), language.t(.aimHint))
            controlRow("1 / 2 · R · E", language.t(.weaponsReloadDefuse))
            controlRow("Esc", language.t(.escapeMenu))
        }
        .padding(18)
        .frame(maxWidth: 520, alignment: .leading)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(UDTheme.cardFill(for: scheme))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(UDTheme.orange.opacity(0.28), lineWidth: 1)
            )
    }

    private func animatedBackdrop(_ t: TimeInterval) -> some View {
        ZStack {
            RadialGradient(
                colors: [UDTheme.orange.opacity(scheme == .dark ? 0.28 : 0.18), Color.clear],
                center: UnitPoint(x: 0.5 + 0.08 * sin(t * 0.4), y: 0.32),
                startRadius: 20,
                endRadius: 520
            )
            RadialGradient(
                colors: [UDTheme.burnt.opacity(0.16), Color.clear],
                center: UnitPoint(x: 0.74, y: 0.82),
                startRadius: 10,
                endRadius: 400
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func controlRow(_ keys: String, _ label: String) -> some View {
        HStack {
            Text(keys)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(UDTheme.orange)
                .frame(width: 148, alignment: .leading)
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(UDTheme.muted(for: scheme))
        }
    }
}

struct ResultView: View {
    @ObservedObject var session: GameSession
    let onAgain: () -> Void
    let onMenu: () -> Void
    @EnvironmentObject private var language: LanguageManager
    @Environment(\.colorScheme) private var scheme

    private var victory: Bool {
        switch session.outcome {
        case .defendersWinElimination, .defendersWinTime, .defendersWinDefuse: return true
        default: return false
        }
    }

    var body: some View {
        ZStack {
            Color("Black").opacity(scheme == .dark ? 0.62 : 0.28).ignoresSafeArea()
                .onAppear { PointerLock.release() }
            VStack(spacing: 18) {
                Text(language.t(victory ? .objectiveComplete : .lineBroken).uppercased())
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(victory ? UDTheme.burnt : UDTheme.orange)
                Text(resultCopy)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(UDTheme.primaryText(for: scheme))
                    .multilineTextAlignment(.center)
                Text("\(session.kills) \(language.t(.kills))")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(UDTheme.muted(for: scheme))
                HStack(spacing: 12) {
                    capsuleButton(language.t(.newRound), action: onAgain)
                    capsuleButton(language.t(.menu), action: onMenu)
                }
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(UDTheme.orange.opacity(0.35), lineWidth: 1)
            )
        }
    }

    private func capsuleButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color("Black"))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(UDTheme.orange)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var resultCopy: String {
        switch session.outcome {
        case .defendersWinElimination: return language.t(.victoryElimination)
        case .defendersWinTime: return language.t(.victoryTime)
        case .defendersWinDefuse: return language.t(.victoryDefuse)
        case .attackersWinPlant: return language.t(.defeatPlant)
        case .attackersWinElimination: return language.t(.defeatEliminated)
        case .inProgress: return ""
        }
    }
}
