import Foundation

enum L10nKey: String, CaseIterable {
    case appName, tagline
    case startRound, settings, language, theme
    case darkMode, lightMode, systemMode
    case move, lookShoot, weaponsReloadDefuse, escapeMenu
    case attackers, health, reloading, holdDefuse
    case artefactArmed, defendSite
    case victoryElimination, victoryTime, victoryDefuse
    case defeatPlant, defeatEliminated
    case objectiveComplete, lineBroken
    case newRound, menu
    case carbine, pistol
    case clickToCapture
    case mouseLook
    case sound
    case sprintJump
    case sprintJumpHint
    case aim
    case aimHint
    case kills
    case map
    case match
    case dust2, aztec, office, mill
    case teammates
    case spectating
}

enum L10n {
    static func string(_ key: L10nKey, language: AppLanguage) -> String {
        let table = language == .portuguese ? pt : en
        return table[key] ?? key.rawValue
    }

    private static let pt: [L10nKey: String] = [
        .appName: "Ultimate Defence",
        .tagline: "Defende o site A. Elimina os atacantes ou impede o artefacto.",
        .startRound: "Iniciar ronda",
        .settings: "Definições",
        .language: "Idioma",
        .theme: "Tema",
        .darkMode: "Escuro",
        .lightMode: "Claro",
        .systemMode: "Sistema",
        .move: "Mover",
        .lookShoot: "Olhar e disparar",
        .weaponsReloadDefuse: "Armas, recarregar, desarmar",
        .escapeMenu: "Menu",
        .attackers: "atacantes",
        .health: "Vida",
        .reloading: "A recarregar",
        .holdDefuse: "Segura E para desarmar",
        .artefactArmed: "Artefacto armado",
        .defendSite: "Site A",
        .victoryElimination: "Vitória: eliminação",
        .victoryTime: "Vitória: o tempo esgotou",
        .victoryDefuse: "Vitória: artefacto desarmado",
        .defeatPlant: "Derrota: o artefacto explodiu",
        .defeatEliminated: "Derrota: foste abatido",
        .objectiveComplete: "Objectivo cumprido",
        .lineBroken: "Linha quebrada",
        .newRound: "Nova ronda",
        .menu: "Menu",
        .carbine: "Carabina UD-4",
        .pistol: "Pistola UD-9",
        .clickToCapture: "Clica na vista se o rato não responder",
        .mouseLook: "Rato + clique",
        .sound: "Som",
        .sprintJump: "Shift · Ctrl · Espaço",
        .sprintJumpHint: "Andar, agachar e saltar",
        .aim: "Botão direito · scroll",
        .aimHint: "Mirar e trocar de arma",
        .kills: "abates",
        .map: "Mapa",
        .match: "Partida",
        .dust2: "Dust II",
        .aztec: "Aztec",
        .office: "Office",
        .mill: "Mill",
        .teammates: "defesa",
        .spectating: "A ronda continua com a tua equipa"
    ]

    private static let en: [L10nKey: String] = [
        .appName: "Ultimate Defence",
        .tagline: "Hold Site A. Eliminate the attackers or stop the artefact.",
        .startRound: "Start round",
        .settings: "Settings",
        .language: "Language",
        .theme: "Theme",
        .darkMode: "Dark",
        .lightMode: "Light",
        .systemMode: "System",
        .move: "Move",
        .lookShoot: "Look and shoot",
        .weaponsReloadDefuse: "Weapons, reload, defuse",
        .escapeMenu: "Menu",
        .attackers: "attackers",
        .health: "Health",
        .reloading: "Reloading",
        .holdDefuse: "Hold E to defuse",
        .artefactArmed: "Artefact armed",
        .defendSite: "Site A",
        .victoryElimination: "Victory: elimination",
        .victoryTime: "Victory: time ran out",
        .victoryDefuse: "Victory: artefact defused",
        .defeatPlant: "Defeat: the artefact detonated",
        .defeatEliminated: "Defeat: you were downed",
        .objectiveComplete: "Objective complete",
        .lineBroken: "Line broken",
        .newRound: "New round",
        .menu: "Menu",
        .carbine: "UD-4 Carbine",
        .pistol: "UD-9 Sidearm",
        .clickToCapture: "Click the view if the mouse is stuck",
        .mouseLook: "Mouse + click",
        .sound: "Sound",
        .sprintJump: "Shift · Ctrl · Space",
        .sprintJumpHint: "Walk, crouch and jump",
        .aim: "Right click · scroll",
        .aimHint: "Aim and switch weapon",
        .kills: "kills",
        .map: "Map",
        .match: "Match",
        .dust2: "Dust II",
        .aztec: "Aztec",
        .office: "Office",
        .mill: "Mill",
        .teammates: "defence",
        .spectating: "The round continues with your team"
    ]
}
