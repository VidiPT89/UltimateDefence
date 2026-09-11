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
            playerAlive: true,
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
            playerAlive: true,
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
        XCTAssertFalse(Collision.isBlocked(resolved, radius: 0.5, walls: [wall]))
    }

    func testUnstickPushesOutOfWall() {
        let wall = AABB(minX: -1, maxX: 1, minZ: -1, maxZ: 1)
        let stuck = SIMD3<Float>(0, 0, 0)
        let free = Collision.unstick(stuck, radius: 0.4, walls: [wall])
        XCTAssertFalse(Collision.isBlocked(free, radius: 0.4, walls: [wall]))
    }

    func testLineOfSightBlockedByWall() {
        let wall = AABB(minX: -2, maxX: 2, minZ: -0.4, maxZ: 0.4)
        let a = SIMD3<Float>(0, 0, -6)
        let b = SIMD3<Float>(0, 0, 6)
        XCTAssertFalse(Collision.losClear(a, b, walls: [wall]))
    }

    func testLineOfSightOpenThroughDoorGap() {
        let left = AABB(minX: -8, maxX: -2, minZ: -0.4, maxZ: 0.4)
        let right = AABB(minX: 2, maxX: 8, minZ: -0.4, maxZ: 0.4)
        let a = SIMD3<Float>(0, 0, -6)
        let b = SIMD3<Float>(0, 0, 6)
        XCTAssertTrue(Collision.losClear(a, b, walls: [left, right]))
    }

    func testMapsBlockSightAcrossRooms() {
        for arena in ArenaMap.allCases {
            let layout = MapBuilder.make(arena).1
            let fromT = layout.attackerSpawns[0]
            let toSite = layout.siteCenter
            XCTAssertFalse(
                Collision.losClear(fromT, toSite, walls: layout.walls),
                "T spawn should not see site through walls on \(arena.rawValue)"
            )
        }
    }

    func testMapSpawnsAreWalkable() {
        for arena in ArenaMap.allCases {
            let layout = MapBuilder.make(arena).1
            XCTAssertFalse(
                Collision.isBlocked(layout.playerSpawn, radius: 0.45, walls: layout.walls),
                "Player spawn blocked in \(arena.rawValue)"
            )
            for spawn in layout.attackerSpawns + layout.defenderSpawns {
                let clear = Collision.unstick(spawn, radius: 0.45, walls: layout.walls)
                XCTAssertFalse(
                    Collision.isBlocked(clear, radius: 0.45, walls: layout.walls),
                    "Bot spawn blocked in \(arena.rawValue)"
                )
            }
        }
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

    func testShootingCutsRunSpeedLikeSource() {
        XCTAssertLessThan(GameRules.shootSpeedMultiplier, 0.4)
        XCTAssertGreaterThan(GameRules.playerSpeed, GameRules.botSpeed)
    }

    func testRunningOpensTheAimMoreThanCrouching() {
        let run = GameRules.aimSpread(moving: true, walking: false, crouching: false, aiming: false)
        let crouch = GameRules.aimSpread(moving: false, walking: false, crouching: true, aiming: true)
        XCTAssertGreaterThan(run, crouch)
        XCTAssertEqual(GameRules.freezeTime, 3)
        XCTAssertEqual(GameRules.roundTime, 105)
    }

    func testBotHitChanceFallsOffWithDistance() {
        let close = GameRules.botHitChance(distance: 2)
        let far = GameRules.botHitChance(distance: 28)
        XCTAssertGreaterThan(close, far)
        XCTAssertLessThanOrEqual(close, 0.70)
        XCTAssertGreaterThanOrEqual(far, 0.16)
    }

    func testMatchSizeCountsAllies() {
        XCTAssertEqual(MatchSize.one.allyCount, 0)
        XCTAssertEqual(MatchSize.two.allyCount, 1)
        XCTAssertEqual(MatchSize.three.allyCount, 2)
        XCTAssertEqual(MatchSize.four.allyCount, 3)
        XCTAssertEqual(MatchSize.five.allyCount, 4)
        XCTAssertEqual(MatchSize.six.allyCount, 5)
    }

    func testPlayerDeathShowsTheResultImmediately() {
        let result = GameRules.outcome(
            playerAlive: false,
            defendersAlive: 3,
            attackersAlive: 3,
            timeLeft: 40,
            bombPlanted: false,
            bombTimeLeft: 40,
            defused: false
        )
        XCTAssertEqual(result, .attackersWinElimination)
    }

    func testLastDefenderDeathEndsTheRound() {
        let result = GameRules.outcome(
            playerAlive: false,
            defendersAlive: 0,
            attackersAlive: 3,
            timeLeft: 40,
            bombPlanted: false,
            bombTimeLeft: 40,
            defused: false
        )
        XCTAssertEqual(result, .attackersWinElimination)
    }

    func testOnlyThePlanterCanArmTheArtefact() {
        XCTAssertTrue(GameRules.canPlant(isTerrorist: true, botId: 0, planterId: 0, planted: false, onSite: true))
        XCTAssertFalse(GameRules.canPlant(isTerrorist: true, botId: 2, planterId: 0, planted: false, onSite: true))
        XCTAssertFalse(GameRules.canPlant(isTerrorist: false, botId: 0, planterId: 0, planted: false, onSite: true))
        XCTAssertFalse(GameRules.canPlant(isTerrorist: true, botId: 0, planterId: 0, planted: true, onSite: true))
        XCTAssertFalse(GameRules.canPlant(isTerrorist: true, botId: 0, planterId: 0, planted: false, onSite: false))
    }

    func testMapsStayFlat() {
        for arena in ArenaMap.allCases {
            let layout = MapBuilder.make(arena).1
            XCTAssertFalse(layout.attackPaths.isEmpty)
            XCTAssertFalse(layout.defendPosts.isEmpty)
        }
    }

    func testRoutePointsAreWalkable() {
        for arena in ArenaMap.allCases {
            let layout = MapBuilder.make(arena).1
            let points = layout.attackPaths.flatMap { $0 } + layout.defendPosts
            for point in points {
                XCTAssertFalse(
                    Collision.isBlocked(point, radius: 0.4, walls: layout.walls),
                    "Blocked route point on \(arena.rawValue) at \(point.x),\(point.z)"
                )
            }
        }
    }

    func testAttackPathsMoveTowardTheSite() {
        for arena in ArenaMap.allCases {
            let layout = MapBuilder.make(arena).1
            for path in layout.attackPaths {
                let start = path.first!
                let end = path.last!
                XCTAssertLessThan(
                    Collision.distanceXZ(end, layout.siteCenter),
                    Collision.distanceXZ(start, layout.siteCenter) + 2,
                    "Path on \(arena.rawValue) should finish nearer the site"
                )
            }
        }
    }

    func testCrateDoesNotBlockSight() {
        let crate = AABB(minX: -1, maxX: 1, minZ: -1, maxZ: 1, blocksSight: false)
        let a = SIMD3<Float>(0, 0, -4)
        let b = SIMD3<Float>(0, 0, 4)
        XCTAssertTrue(Collision.losClear(a, b, walls: [crate]))
    }

    func testMapsHaveRadarBounds() {
        for arena in ArenaMap.allCases {
            let layout = MapBuilder.make(arena).1
            XCTAssertGreaterThan(layout.mapMaxX, layout.mapMinX)
            XCTAssertGreaterThan(layout.mapMaxZ, layout.mapMinZ)
        }
    }

    func testKillFeedKeepsTheLastFiveLines() {
        let session = GameSession()
        for index in 0..<7 {
            session.pushKill(killer: .you, victim: .t)
            XCTAssertEqual(session.killFeed.last?.id, index + 1)
        }
        XCTAssertEqual(session.killFeed.count, 5)
        XCTAssertEqual(session.killFeed.first?.id, 3)
    }
}
