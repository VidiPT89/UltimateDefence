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
            defendersAlive: 1,
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
            defendersAlive: 1,
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
            defendersAlive: 1,
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

    func testBotHitChanceFallsOffWithDistance() {
        let close = GameRules.botHitChance(distance: 2)
        let far = GameRules.botHitChance(distance: 28)
        XCTAssertGreaterThan(close, far)
        XCTAssertLessThanOrEqual(close, 0.55)
        XCTAssertGreaterThanOrEqual(far, 0.14)
    }

    func testAimSpreadGrowsWhenMoving() {
        let still = GameRules.aimSpread(moving: false, sprinting: false)
        let run = GameRules.aimSpread(moving: true, sprinting: true)
        let walk = GameRules.aimSpread(moving: true, sprinting: false, walking: true)
        let ads = GameRules.aimSpread(moving: true, sprinting: false, aiming: true)
        XCTAssertGreaterThan(run, still)
        XCTAssertLessThan(walk, run)
        XCTAssertLessThan(ads, run)
    }

    func testMatchSizeCountsAllies() {
        XCTAssertEqual(MatchSize.one.allyCount, 0)
        XCTAssertEqual(MatchSize.two.allyCount, 1)
        XCTAssertEqual(MatchSize.three.allyCount, 2)
        XCTAssertEqual(MatchSize.four.allyCount, 3)
        XCTAssertEqual(MatchSize.five.allyCount, 4)
        XCTAssertEqual(MatchSize.six.allyCount, 5)
    }

    func testPlayerDeathDoesNotEndRoundIfAlliesRemain() {
        let result = GameRules.outcome(
            defendersAlive: 2,
            attackersAlive: 3,
            timeLeft: 40,
            bombPlanted: false,
            bombTimeLeft: 40,
            defused: false
        )
        XCTAssertEqual(result, .inProgress)
    }

    func testLastDefenderDownLosesTheRound() {
        let result = GameRules.outcome(
            defendersAlive: 0,
            attackersAlive: 2,
            timeLeft: 40,
            bombPlanted: false,
            bombTimeLeft: 40,
            defused: false
        )
        XCTAssertEqual(result, .attackersWinElimination)
    }
}
