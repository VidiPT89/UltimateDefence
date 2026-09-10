import Foundation

final class GameSession: ObservableObject {
    @Published var screen: Screen = .menu
    @Published var health = GameRules.playerMaxHealth
    @Published var mag = WeaponStats.rifle.magazine
    @Published var reserve = WeaponStats.rifle.reserve
    @Published var slot: WeaponSlot = .rifle
    @Published var timeLeft = GameRules.roundTime
    @Published var bombPlanted = false
    @Published var defuseProgress: Double = 0
    @Published var plantHint = false
    @Published var attackersAlive = GameRules.attackerCount
    @Published var outcome: RoundOutcome = .inProgress
    @Published var reloading = false
    @Published var capturedMouse = false
    @Published var hitTick = 0
    @Published var damageTick = 0
    @Published var kills = 0
    @Published var aiming = false
    @Published var moving = false

    enum Screen {
        case menu
        case playing
        case result
    }
}
