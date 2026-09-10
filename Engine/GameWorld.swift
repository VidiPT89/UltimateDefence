import SceneKit
import AppKit
import QuartzCore
import simd

final class GameWorld: NSObject, SCNSceneRendererDelegate {
    let session: GameSession
    let scene: SCNScene
    let layout: MapLayout
    let player = PlayerController()
    private var bots: [BotActor] = []
    private var lastTime: TimeInterval?
    private var roundElapsed: TimeInterval = 0
    private var bombElapsed: TimeInterval = 0
    private var bombPlanted = false
    private var defused = false
    private var muzzle: SCNNode?

    init(session: GameSession) {
        self.session = session
        let built = MapBuilder.make()
        scene = built.0
        layout = built.1
        super.init()
        resetRound()
    }

    func resetRound() {
        lastTime = nil
        roundElapsed = 0
        bombElapsed = 0
        bombPlanted = false
        defused = false
        player.keys.removeAll()
        player.shooting = false
        player.health = GameRules.playerMaxHealth
        player.slot = .rifle
        player.mag = [.rifle: WeaponStats.rifle.magazine, .pistol: WeaponStats.pistol.magazine]
        player.reserve = [.rifle: WeaponStats.rifle.reserve, .pistol: WeaponStats.pistol.reserve]
        player.lastShot = -10
        player.reloadingUntil = 0
        player.defuseProgress = 0
        player.node.removeFromParentNode()
        player.setup(at: layout.playerSpawn)
        scene.rootNode.addChildNode(player.node)

        bots.forEach { $0.node.removeFromParentNode() }
        bots = layout.attackerSpawns.enumerated().map { index, spawn in
            let bot = BotActor(id: index, at: spawn)
            scene.rootNode.addChildNode(bot.node)
            return bot
        }
        muzzle?.removeFromParentNode()
        publishHUD()
        session.outcome = .inProgress
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard session.screen == .playing, session.outcome == .inProgress else { return }
        let dt: Float
        if let lastTime {
            dt = Float(min(0.05, time - lastTime))
        } else {
            dt = 1.0 / 60.0
        }
        lastTime = time
        tick(dt: dt, now: time)
    }

    private func tick(dt: Float, now: TimeInterval) {
        player.finishReloadIfNeeded(now: now)
        player.move(dt: dt, walls: layout.walls)
        handleCombat(now: now)
        updateBots(dt: dt, now: now)
        updateObjective(dt: dt)
        evaluateRound()
        publishHUD()
    }

    private func handleCombat(now: TimeInterval) {
        guard player.canShoot(now: now) else { return }
        player.consumeShot(now: now)
        flashMuzzle()
        WeaponRig.kick(player.cameraNode)
        let origin = player.cameraNode.worldPosition
        let dir = lookDirection()
        let dest = SCNVector3(
            origin.x + CGFloat(dir.x * player.currentStats.range),
            origin.y + CGFloat(dir.y * player.currentStats.range),
            origin.z + CGFloat(dir.z * player.currentStats.range)
        )
        let hits = scene.rootNode.hitTestWithSegment(from: origin, to: dest, options: [
            SCNHitTestOption.searchMode.rawValue: SCNHitTestSearchMode.closest.rawValue
        ])
        guard let hit = hits.first else {
            let miss = SCNVector3(
                origin.x + CGFloat(dir.x * 18),
                origin.y + CGFloat(dir.y * 18),
                origin.z + CGFloat(dir.z * 18)
            )
            FX.tracer(from: origin, to: miss, in: scene.rootNode)
            return
        }
        FX.tracer(from: origin, to: hit.worldCoordinates, in: scene.rootNode)
        FX.spark(at: hit.worldCoordinates, in: scene.rootNode, color: NSColor(calibratedRed: 1, green: 0.7, blue: 0.2, alpha: 1))
        let name = hit.node.name ?? hit.node.parent?.name ?? ""
        guard name.hasPrefix(NodeName.botPrefix) else { return }
        session.hitTick += 1
        let headshot = name.contains(NodeName.headSuffix)
        let dmg = GameRules.applyDamage(
            base: player.currentStats.damage,
            headshot: headshot,
            multiplier: player.currentStats.headshotMultiplier
        )
        if let bot = bots.first(where: { name.hasPrefix("\(NodeName.botPrefix)\($0.id)") }) {
            bot.takeDamage(dmg)
        }
    }

    private func updateBots(dt: Float, now: TimeInterval) {
        for bot in bots where bot.isAlive {
            let action = bot.update(
                dt: dt,
                now: now,
                player: player,
                site: layout.siteCenter,
                walls: layout.walls,
                bombPlanted: bombPlanted,
                world: scene.rootNode
            )
            switch action {
            case .idle:
                break
            case .shoot:
                if Float.random(in: 0...1) < 0.42 {
                    let before = player.health
                    player.takeDamage(Int.random(in: 8...16))
                    if player.health < before {
                        session.damageTick += 1
                    }
                }
            case .plant:
                bombPlanted = true
            }
        }
    }

    private func updateObjective(dt: Float) {
        if bombPlanted {
            bombElapsed += TimeInterval(dt)
        } else {
            roundElapsed += TimeInterval(dt)
        }

        let onSite = Collision.distanceXZ(player.worldPosition, layout.siteCenter) < GameRules.siteRadius
        session.plantHint = onSite && bombPlanted
        if bombPlanted && player.interacting && onSite && player.isAlive {
            player.defuseProgress += TimeInterval(dt)
            if player.defuseProgress >= GameRules.defuseTime {
                defused = true
            }
        } else {
            player.defuseProgress = max(0, player.defuseProgress - TimeInterval(dt))
        }
    }

    private func evaluateRound() {
        let timeLeft = max(0, GameRules.roundTime - roundElapsed)
        let bombLeft = max(0, GameRules.bombTime - bombElapsed)
        let aliveBots = bots.filter(\.isAlive).count
        let result = GameRules.outcome(
            playerAlive: player.isAlive,
            attackersAlive: aliveBots,
            timeLeft: timeLeft,
            bombPlanted: bombPlanted,
            bombTimeLeft: bombLeft,
            defused: defused
        )
        if result != .inProgress {
            session.outcome = result
            session.screen = .result
            session.capturedMouse = false
        }
    }

    private func publishHUD() {
        session.health = player.health
        session.mag = player.currentMag
        session.reserve = player.reserve[player.slot] ?? 0
        session.weaponName = player.currentStats.name
        session.slot = player.slot
        session.timeLeft = bombPlanted ? max(0, GameRules.bombTime - bombElapsed) : max(0, GameRules.roundTime - roundElapsed)
        session.bombPlanted = bombPlanted
        session.bombTimeLeft = max(0, GameRules.bombTime - bombElapsed)
        session.defuseProgress = min(1, player.defuseProgress / GameRules.defuseTime)
        session.attackersAlive = bots.filter(\.isAlive).count
        session.reloading = CACurrentMediaTime() < player.reloadingUntil
        session.moving = player.moving
    }

    private func lookDirection() -> SIMD3<Float> {
        let pitch = player.pitch
        let yaw = player.yaw
        let cy = cos(pitch)
        return SIMD3(-sin(yaw) * cy, sin(pitch), -cos(yaw) * cy)
    }

    private func flashMuzzle() {
        muzzle?.removeFromParentNode()
        let flash = SCNSphere(radius: 0.05)
        flash.firstMaterial = SCNMaterial()
        flash.firstMaterial?.diffuse.contents = NSColor.orange
        flash.firstMaterial?.emission.contents = NSColor.yellow
        let node = SCNNode(geometry: flash)
        node.position = SCNVector3(0.18, -0.12, -0.45)
        player.cameraNode.addChildNode(node)
        muzzle = node
        node.runAction(.sequence([.wait(duration: 0.04), .removeFromParentNode()]))
    }

    func handleKey(_ code: UInt16, down: Bool) {
        if down {
            player.keys.insert(code)
            switch code {
            case 15: player.startReload(now: CACurrentMediaTime()) // R
            case 18: player.selectSlot(.rifle) // 1
            case 19: player.selectSlot(.pistol) // 2
            case 14: player.interacting = true // E
            case 53: // Esc
                session.capturedMouse = false
                session.screen = .menu
            default: break
            }
        } else {
            player.keys.remove(code)
            if code == 14 { player.interacting = false }
        }
    }
}
