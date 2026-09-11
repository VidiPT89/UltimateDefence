import Foundation

enum ArenaMap: String, CaseIterable, Identifiable {
    case dust2
    case aztec
    case office
    case mill

    var id: String { rawValue }
}

enum MatchSize: Int, CaseIterable, Identifiable {
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6

    var id: Int { rawValue }
    var allyCount: Int { max(0, rawValue - 1) }
    var label: String { "\(rawValue)v\(rawValue)" }
}

enum Difficulty: String, CaseIterable, Identifiable {
    case easy
    case normal
    case hard

    var id: String { rawValue }

    var hitScale: Float {
        switch self {
        case .easy: return 0.52
        case .normal: return 1
        case .hard: return 1.38
        }
    }

    var speedScale: Float {
        switch self {
        case .easy: return 0.82
        case .normal: return 1
        case .hard: return 1.14
        }
    }

    var damageScale: Float {
        switch self {
        case .easy: return 0.65
        case .normal: return 1
        case .hard: return 1.3
        }
    }
}

enum BotTeam {
    case terrorist
    case counter
}

enum CombatSide: Equatable {
    case you, ct, t
}

struct KillLine: Identifiable, Equatable {
    let id: Int
    let killer: CombatSide
    let victim: CombatSide
}

struct RadarBlip: Identifiable, Equatable {
    let id: String
    let x: Float
    let z: Float
    let kind: Kind

    enum Kind: Equatable {
        case player, ally, enemy, site, bomb
    }
}
