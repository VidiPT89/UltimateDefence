import Foundation
import Combine

final class GameSession: ObservableObject {
    @Published var screen: Screen = .menu
    @Published var health = GameRules.playerMaxHealth
    @Published var mag = WeaponStats.rifle.magazine
    @Published var reserve = WeaponStats.rifle.reserve
    @Published var weaponName = WeaponStats.rifle.name
    @Published var timeLeft = GameRules.roundTime
    @Published var bombPlanted = false
    @Published var bombTimeLeft = GameRules.bombTime
    @Published var defuseProgress: Double = 0
    @Published var plantHint = false
    @Published var attackersAlive = GameRules.attackerCount
    @Published var outcome: RoundOutcome = .inProgress
    @Published var reloading = false
    @Published var capturedMouse = false
    @Published var hitTick = 0
    @Published var damageTick = 0
    @Published var moving = false

    enum Screen {
        case menu
        case playing
        case result
    }

    var resultTitle: String {
        switch outcome {
        case .defendersWinElimination: return "Vitória: eliminação"
        case .defendersWinTime: return "Vitória: o tempo esgotou"
        case .defendersWinDefuse: return "Vitória: artefacto desarmado"
        case .attackersWinPlant: return "Derrota: o artefacto explodiu"
        case .attackersWinElimination: return "Derrota: foste abatido"
        case .inProgress: return ""
        }
    }
}
