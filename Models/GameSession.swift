import Foundation
import simd

final class GameSession: ObservableObject {
    @Published var screen: Screen = .menu
    @Published var health = GameRules.playerMaxHealth
    @Published var mag = WeaponStats.rifle.magazine
    @Published var reserve = WeaponStats.rifle.reserve
    @Published var slot: WeaponSlot = .rifle
    @Published var timeLeft = GameRules.roundTime
    @Published var freezeLeft: TimeInterval = 0
    @Published var bombPlanted = false
    @Published var defuseProgress: Double = 0
    @Published var plantHint = false
    @Published var attackersAlive = 5
    @Published var defendersAlive = 5
    @Published var arena: ArenaMap = .dust2
    @Published var matchSize: MatchSize = .five
    @Published var difficulty: Difficulty = .normal
    @Published var outcome: RoundOutcome = .inProgress
    @Published var reloading = false
    @Published var capturedMouse = false
    @Published var hitTick = 0
    @Published var damageTick = 0
    @Published var kills = 0
    @Published var aiming = false
    @Published var moving = false
    @Published var radarBlips: [RadarBlip] = []
    @Published var radarMe = SIMD3<Float>(repeating: 0)
    @Published var radarYaw: Float = 0
    @Published var radarSpan: Float = 80
    @Published var killFeed: [KillLine] = []
    private var feedSeq = 0

    func pushKill(killer: CombatSide, victim: CombatSide) {
        feedSeq += 1
        killFeed = Array((killFeed + [KillLine(id: feedSeq, killer: killer, victim: victim)]).suffix(5))
    }

    func clearMatchFeed() {
        killFeed = []
        radarBlips = []
    }

    enum Screen {
        case menu
        case playing
        case result
    }
}
