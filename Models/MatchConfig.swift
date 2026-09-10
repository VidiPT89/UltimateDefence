import Foundation

enum ArenaMap: String, CaseIterable, Identifiable {
    case sandlot
    case dust2
    case mill

    var id: String { rawValue }
}

enum MatchSize: Int, CaseIterable, Identifiable {
    case two = 2
    case three = 3
    case five = 5

    var id: Int { rawValue }
    var allyCount: Int { rawValue - 1 }
}

enum BotTeam {
    case terrorist
    case counter
}
