import Foundation

enum RoundOutcome: Equatable {
    case inProgress
    case defendersWinElimination
    case defendersWinTime
    case defendersWinDefuse
    case attackersWinPlant
    case attackersWinElimination
}

struct WeaponStats: Equatable {
    let name: String
    let damage: Int
    let headshotMultiplier: Double
    let fireInterval: TimeInterval
    let magazine: Int
    let reserve: Int
    let reloadTime: TimeInterval
    let range: Float

    static let rifle = WeaponStats(
        name: "UD-4 Carbine",
        damage: 28,
        headshotMultiplier: 2.4,
        fireInterval: 0.095,
        magazine: 30,
        reserve: 90,
        reloadTime: 2.1,
        range: 80
    )

    static let pistol = WeaponStats(
        name: "UD-9 Sidearm",
        damage: 34,
        headshotMultiplier: 2.1,
        fireInterval: 0.18,
        magazine: 12,
        reserve: 36,
        reloadTime: 1.4,
        range: 45
    )
}

enum WeaponSlot: Int, CaseIterable {
    case rifle = 0
    case pistol = 1

    var stats: WeaponStats {
        switch self {
        case .rifle: return .rifle
        case .pistol: return .pistol
        }
    }
}

struct GameRules {
    static let roundTime: TimeInterval = 90
    static let plantTime: TimeInterval = 3.5
    static let bombTime: TimeInterval = 40
    static let defuseTime: TimeInterval = 5
    static let playerMaxHealth = 100
    static let botMaxHealth = 100
    static let attackerCount = 4
    static let siteRadius: Float = 4.5
    static let playerSpeed: Float = 8.5
    static let sprintMultiplier: Float = 1.32
    static let botSpeed: Float = 5.4
    static let jumpVelocity: Float = 7.4
    static let gravity: Float = 22

    static func applyDamage(base: Int, headshot: Bool, multiplier: Double) -> Int {
        let raw = headshot ? Double(base) * multiplier : Double(base)
        return max(1, Int(raw.rounded()))
    }

    static func remainingHealth(current: Int, damage: Int) -> Int {
        max(0, current - max(0, damage))
    }

    static func outcome(
        playerAlive: Bool,
        attackersAlive: Int,
        timeLeft: TimeInterval,
        bombPlanted: Bool,
        bombTimeLeft: TimeInterval,
        defused: Bool
    ) -> RoundOutcome {
        if defused { return .defendersWinDefuse }
        if bombPlanted && bombTimeLeft <= 0 { return .attackersWinPlant }
        if !playerAlive { return .attackersWinElimination }
        if attackersAlive <= 0 && !bombPlanted { return .defendersWinElimination }
        if !bombPlanted && timeLeft <= 0 { return .defendersWinTime }
        return .inProgress
    }

    static func botHitChance(distance: Float) -> Float {
        let closeness = 1 - min(1, max(0, distance / 30))
        return 0.14 + closeness * 0.36
    }

    static func aimSpread(moving: Bool, sprinting: Bool) -> Float {
        var spread: Float = 0.008
        if moving { spread += 0.018 }
        if sprinting { spread += 0.012 }
        return spread
    }
}
