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
    let damage: Int
    let headshotMultiplier: Double
    let fireInterval: TimeInterval
    let magazine: Int
    let reserve: Int
    let reloadTime: TimeInterval
    let range: Float

    static let rifle = WeaponStats(
        damage: 27,
        headshotMultiplier: 4.0,
        fireInterval: 0.1,
        magazine: 30,
        reserve: 90,
        reloadTime: 2.1,
        range: 80
    )

    static let pistol = WeaponStats(
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
    static let siteRadius: Float = 4.5
    static let playerSpeed: Float = 6.6
    static let walkMultiplier: Float = 0.52
    static let crouchMultiplier: Float = 0.34
    static let botSpeed: Float = 4.6
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
        defendersAlive: Int,
        attackersAlive: Int,
        timeLeft: TimeInterval,
        bombPlanted: Bool,
        bombTimeLeft: TimeInterval,
        defused: Bool
    ) -> RoundOutcome {
        if defused { return .defendersWinDefuse }
        if bombPlanted && bombTimeLeft <= 0 { return .attackersWinPlant }
        if attackersAlive <= 0 && !bombPlanted { return .defendersWinElimination }
        if defendersAlive <= 0 { return .attackersWinElimination }
        if !bombPlanted && timeLeft <= 0 { return .defendersWinTime }
        return .inProgress
    }

    static func botHitChance(distance: Float) -> Float {
        let closeness = 1 - min(1, max(0, distance / 30))
        return 0.14 + closeness * 0.36
    }

    static func aimSpread(
        moving: Bool,
        sprinting: Bool,
        aiming: Bool = false,
        walking: Bool = false,
        crouching: Bool = false,
        airborne: Bool = false
    ) -> Float {
        var spread: Float = 0.006
        if moving { spread += 0.022 }
        if sprinting { spread += 0.01 }
        if walking { spread *= 0.45 }
        if crouching { spread *= 0.4 }
        if aiming { spread *= 0.42 }
        if airborne { spread += 0.05 }
        return spread
    }
}
