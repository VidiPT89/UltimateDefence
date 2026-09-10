import XCTest
@testable import UltimateDefence

final class GameRulesTests: XCTestCase {
    func testHeadshotMultipliesDamage() {
        let body = GameRules.applyDamage(base: 28, headshot: false, multiplier: 2.4)
        let head = GameRules.applyDamage(base: 28, headshot: true, multiplier: 2.4)
        XCTAssertEqual(body, 28)
        XCTAssertEqual(head, 67)
    }

    func testHealthNeverGoesNegative() {
        XCTAssertEqual(GameRules.remainingHealth(current: 10, damage: 40), 0)
        XCTAssertEqual(GameRules.remainingHealth(current: 80, damage: 15), 65)
    }

    func testDefendersWinOnTimeIfBombNotPlanted() {
        let result = GameRules.outcome(
            playerAlive: true,
            attackersAlive: 2,
            timeLeft: 0,
            bombPlanted: false,
            bombTimeLeft: 40,
            defused: false
        )
        XCTAssertEqual(result, .defendersWinTime)
    }

    func testAttackersWinIfBombExplodes() {
        let result = GameRules.outcome(
            playerAlive: true,
            attackersAlive: 0,
            timeLeft: 20,
            bombPlanted: true,
            bombTimeLeft: 0,
            defused: false
        )
        XCTAssertEqual(result, .attackersWinPlant)
    }

    func testDefuseBeatsExplosion() {
        let result = GameRules.outcome(
            playerAlive: true,
            attackersAlive: 1,
            timeLeft: 10,
            bombPlanted: true,
            bombTimeLeft: 0,
            defused: true
        )
        XCTAssertEqual(result, .defendersWinDefuse)
    }

    func testCollisionStopsInsideWall() {
        let wall = AABB(minX: -1, maxX: 1, minZ: -1, maxZ: 1)
        let start = SIMD3<Float>(0, 1.6, -3)
        let proposed = SIMD3<Float>(0, 1.6, 0)
        let resolved = Collision.resolve(position: start, proposed: proposed, radius: 0.5, walls: [wall])
        XCTAssertLessThan(resolved.z, -1)
    }

    func testLocalizationCoversEveryKey() {
        for key in L10nKey.allCases {
            let pt = L10n.string(key, language: .portuguese)
            let en = L10n.string(key, language: .english)
            XCTAssertFalse(pt.isEmpty, "Missing PT for \(key)")
            XCTAssertFalse(en.isEmpty, "Missing EN for \(key)")
            XCTAssertNotEqual(pt, key.rawValue)
        }
    }
}
