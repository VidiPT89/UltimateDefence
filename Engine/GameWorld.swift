import SceneKit
import AppKit
import QuartzCore
import simd

final class GameWorld: NSObject, SCNSceneRendererDelegate {
    let session: GameSession
    let sounds: SoundManager
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
    private var lastStep: TimeInterval = 0
    private var lastDry: TimeInterval = 0
    private var lastBeep: TimeInterval = 0
    private var wasReloading = false

    init(session: GameSession, sounds: SoundManager) {
        self.session = session
        self.sounds = sounds
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
        player.yaw = .pi * 0.85
        player.pitch = 0
        player.bob = 0
        player.interacting = false
        player.vertical = 0
        player.grounded = true
        player.aiming = false
        player.punch = 0
        player.roundStart = CACurrentMediaTime()
        wasReloading = false
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
        session.kills = 0
        session.aiming = false
        session.moving = false
        session.outcome = .inProgress
        publishHUD()
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
        let reloading = now < player.reloadingUntil
        if reloading && !wasReloading {
            sounds.playReload()
        }
        wasReloading = reloading
        player.move(dt: dt, walls: layout.walls)
        if player.moving, player.grounded, now - lastStep > (player.sprinting ? 0.28 : 0.38) {
            lastStep = now
            sounds.playStep()
        }
        handleCombat(now: now)
        updateBots(dt: dt, now: now)
        updateObjective(dt: dt, now: now)
        evaluateRound()
        publishHUD()
    }

    private func handleCombat(now: TimeInterval) {
        if player.shooting, player.currentMag == 0, now >= player.reloadingUntil, now - lastDry > 0.28 {
            lastDry = now
            sounds.playDry()
        }
        guard player.canShoot(now: now) else { return }
        player.consumeShot(now: now)
        sounds.playShoot()
        player.punch += player.slot == .rifle ? 0.024 : 0.04
        player.yaw += Float.random(in: -0.012...0.012)
        player.applyLook()
        flashMuzzle()
        WeaponRig.kick(player.cameraNode)
        let origin = player.cameraNode.worldPosition
        let dir = lookDirection()
        let start = SCNVector3(
            origin.x + CGFloat(dir.x * 0.85),
            origin.y + CGFloat(dir.y * 0.85),
            origin.z + CGFloat(dir.z * 0.85)
        )
        let dest = SCNVector3(
            origin.x + CGFloat(dir.x * player.currentStats.range),
            origin.y + CGFloat(dir.y * player.currentStats.range),
            origin.z + CGFloat(dir.z * player.currentStats.range)
        )
        let hits = scene.rootNode.hitTestWithSegment(from: start, to: dest, options: [
            SCNHitTestOption.searchMode.rawValue: SCNHitTestSearchMode.closest.rawValue
        ]).filter { !Self.isPlayerGeometry($0.node) }
        guard let hit = hits.first else {
            let miss = SCNVector3(
                origin.x + CGFloat(dir.x * 18),
                origin.y + CGFloat(dir.y * 18),
                origin.z + CGFloat(dir.z * 18)
            )
            FX.tracer(from: start, to: miss, in: scene.rootNode)
            return
        }
        FX.tracer(from: start, to: hit.worldCoordinates, in: scene.rootNode)
        FX.spark(at: hit.worldCoordinates, in: scene.rootNode, color: NSColor(calibratedRed: 1, green: 0.7, blue: 0.2, alpha: 1))
        let name = hit.node.name ?? hit.node.parent?.name ?? ""
        guard name.hasPrefix(NodeName.botPrefix) else { return }
        onMain { self.session.hitTick += 1 }
        sounds.playHit()
        let headshot = name.contains(NodeName.headSuffix)
        let dmg = GameRules.applyDamage(
            base: player.currentStats.damage,
            headshot: headshot,
            multiplier: player.currentStats.headshotMultiplier
        )
        if let bot = bots.first(where: { name.hasPrefix("\(NodeName.botPrefix)\($0.id)") }) {
            let wasAlive = bot.isAlive
            bot.takeDamage(dmg)
            if wasAlive && !bot.isAlive {
                onMain { self.session.kills += 1 }
            }
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
                sounds.playShoot()
                let muzzlePos = SCNVector3(
                    bot.node.worldPosition.x,
                    bot.node.worldPosition.y + 1.2,
                    bot.node.worldPosition.z
                )
                FX.spark(at: muzzlePos, in: scene.rootNode, color: NSColor(calibratedRed: 1, green: 0.7, blue: 0.2, alpha: 1))
                FX.tracer(from: muzzlePos, to: player.cameraNode.worldPosition, in: scene.rootNode)
                let distance = Collision.distanceXZ(
                    SIMD3(Float(bot.node.position.x), 0, Float(bot.node.position.z)),
                    player.worldPosition
                )
                if Float.random(in: 0...1) < GameRules.botHitChance(distance: distance) {
                    let before = player.health
                    player.takeDamage(Int.random(in: 8...16))
                    if player.health < before {
                        onMain { self.session.damageTick += 1 }
                        sounds.playHit()
                    }
                }
            case .plant:
                if !bombPlanted {
                    bombPlanted = true
                    sounds.playPlantBeep()
                }
            }
        }
    }

    private func updateObjective(dt: Float, now: TimeInterval) {
        if bombPlanted {
            bombElapsed += TimeInterval(dt)
        } else {
            roundElapsed += TimeInterval(dt)
        }

        let onSite = Collision.distanceXZ(player.worldPosition, layout.siteCenter) < GameRules.siteRadius
        onMain { self.session.plantHint = onSite && self.bombPlanted }
        if bombPlanted && player.interacting && onSite && player.isAlive {
            player.defuseProgress += TimeInterval(dt)
            if now - lastBeep > 0.45 {
                lastBeep = now
                sounds.playPlantBeep()
            }
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
            if result == .attackersWinPlant {
                let site = layout.siteCenter
                FX.explosion(at: SCNVector3(site.x, 1.2, site.z), in: scene.rootNode)
                sounds.playExplosion()
            }
            onMain {
                self.session.outcome = result
                self.session.screen = .result
                self.session.capturedMouse = false
            }
            switch result {
            case .defendersWinElimination, .defendersWinTime, .defendersWinDefuse:
                sounds.playWin()
            default:
                sounds.playLose()
            }
        }
    }

    private func publishHUD() {
        let health = player.health
        let mag = player.currentMag
        let reserve = player.reserve[player.slot] ?? 0
        let slot = player.slot
        let timeLeft = bombPlanted ? max(0, GameRules.bombTime - bombElapsed) : max(0, GameRules.roundTime - roundElapsed)
        let planted = bombPlanted
        let defuse = min(1, player.defuseProgress / GameRules.defuseTime)
        let attackers = bots.filter(\.isAlive).count
        let reloading = CACurrentMediaTime() < player.reloadingUntil
        let moving = player.moving
        let aiming = player.aiming
        onMain {
            if self.session.health != health { self.session.health = health }
            if self.session.mag != mag { self.session.mag = mag }
            if self.session.reserve != reserve { self.session.reserve = reserve }
            if self.session.slot != slot { self.session.slot = slot }
            if abs(self.session.timeLeft - timeLeft) > 0.05 { self.session.timeLeft = timeLeft }
            if self.session.bombPlanted != planted { self.session.bombPlanted = planted }
            if abs(self.session.defuseProgress - defuse) > 0.01 { self.session.defuseProgress = defuse }
            if self.session.attackersAlive != attackers { self.session.attackersAlive = attackers }
            if self.session.reloading != reloading { self.session.reloading = reloading }
            if self.session.moving != moving { self.session.moving = moving }
            if self.session.aiming != aiming { self.session.aiming = aiming }
        }
    }

    private func onMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    private func lookDirection() -> SIMD3<Float> {
        let spread = GameRules.aimSpread(
            moving: player.moving,
            sprinting: player.sprinting,
            aiming: player.aiming,
            walking: player.walking,
            crouching: player.crouching,
            airborne: !player.grounded
        )
        let pitch = player.pitch + player.punch + Float.random(in: -spread...spread)
        let yaw = player.yaw + Float.random(in: -spread...spread)
        let cy = cos(pitch)
        return SIMD3(-sin(yaw) * cy, sin(pitch), -cos(yaw) * cy)
    }

    private func flashMuzzle() {
        muzzle?.removeFromParentNode()
        let flash = SCNSphere(radius: 0.08)
        flash.firstMaterial = SCNMaterial()
        flash.firstMaterial?.diffuse.contents = NSColor(calibratedRed: 0.98, green: 0.61, blue: 0, alpha: 1)
        flash.firstMaterial?.emission.contents = NSColor(calibratedRed: 1, green: 0.85, blue: 0.35, alpha: 1)
        flash.firstMaterial?.emission.intensity = 2
        let node = SCNNode(geometry: flash)
        node.position = SCNVector3(0.22, -0.14, -0.58)
        player.cameraNode.addChildNode(node)
        muzzle = node
        node.runAction(.sequence([.wait(duration: 0.045), .removeFromParentNode()]))
    }

    func cycleWeapon(_ direction: Int) {
        let all = WeaponSlot.allCases
        guard let idx = all.firstIndex(of: player.slot) else { return }
        let next = all[(idx + direction + all.count) % all.count]
        player.selectSlot(next)
        sounds.playUI()
    }

    func handleKey(_ code: UInt16, down: Bool) {
        if down {
            player.keys.insert(code)
            switch code {
            case 15: player.startReload(now: CACurrentMediaTime()) // R
            case 18:
                player.selectSlot(.rifle)
                sounds.playUI()
            case 19:
                player.selectSlot(.pistol)
                sounds.playUI()
            case 14: player.interacting = true // E
            case 53: // Esc
                onMain {
                    self.session.capturedMouse = false
                    self.session.screen = .menu
                }
            default: break
            }
        } else {
            player.keys.remove(code)
            if code == 14 { player.interacting = false }
        }
    }

    private static func isPlayerGeometry(_ node: SCNNode) -> Bool {
        var current: SCNNode? = node
        while let node = current {
            let name = node.name ?? ""
            if name == NodeName.player || name == NodeName.camera || name == "weaponRig" {
                return true
            }
            current = node.parent
        }
        return false
    }
}
