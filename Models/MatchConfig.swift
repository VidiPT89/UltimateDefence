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
