import SceneKit
import AppKit
import simd

final class BotActor {
    let id: Int
    let team: BotTeam
    let node: SCNNode
    let head: SCNNode
    var health = GameRules.botMaxHealth
    var lastShot: TimeInterval = 0
    var plantProgress: TimeInterval = 0
    private var wander: Float

    var isAlive: Bool { health > 0 }
    var isTerrorist: Bool { team == .terrorist }

    init(id: Int, team: BotTeam, at spawn: SIMD3<Float>) {
        self.id = id
        self.team = team
        wander = Float(id) * 0.55 + (team == .terrorist ? 0 : 1.7)
        let prefix = team == .terrorist ? NodeName.terroristPrefix : NodeName.counterPrefix
        node = SCNNode()
        node.name = "\(prefix)\(id)"
        node.position = SCNVector3(spawn.x, 0, spawn.z)
        head = CharacterMesh.attach(
            to: node,
            team: team,
            variant: id,
            name: "\(prefix)\(id)",
            headName: "\(prefix)\(id)\(NodeName.headSuffix)"
        )
    }

    func update(
        dt: Float,
        now: TimeInterval,
        player: PlayerController,
        enemies: [BotActor],
        site: SIMD3<Float>,
        walls: [AABB],
        bombPlanted: Bool,
        world: SCNNode
    ) -> BotAction {
        guard isAlive else { return .idle }
        let pos = SIMD3(Float(node.position.x), 0, Float(node.position.z))
        let playerPos = player.worldPosition
        var aim = site
        var canShoot = false
        var shootPlayer = false
        var shootBot: BotActor?

        if isTerrorist {
            let seesPlayer = player.isAlive && visible(from: pos, to: playerPos, world: world)
            let visibleEnemy = enemies.first { $0.isAlive && visible(from: pos, to: $0.xz, world: world) }
            if seesPlayer {
                aim = playerPos
                canShoot = true
                shootPlayer = true
            } else if let visibleEnemy {
                aim = visibleEnemy.xz
                canShoot = true
                shootBot = visibleEnemy
            } else if id == 0 {
                aim = site
            } else {
                aim = site
            }
        } else {
            let visibleEnemy = enemies.first { $0.isAlive && visible(from: pos, to: $0.xz, world: world) }
            if let visibleEnemy {
                aim = visibleEnemy.xz
                canShoot = true
                shootBot = visibleEnemy
            } else {
                aim = site
            }
        }

        var dir = SIMD3(aim.x - pos.x, 0, aim.z - pos.z)
        let len = simd_length(dir)
        let hold = canShoot && len < 14
        if len > 0.6, !hold || len > 9 {
            dir /= len
            wander += dt * (canShoot ? 2.1 : 1)
            let side = SIMD3(-dir.z, 0, dir.x) * sin(wander) * 0.5
            let speed = GameRules.botSpeed * (plantProgress > 0 ? 0.28 : 1)
            let next = pos + (dir + side) * speed * dt
            let resolved = Collision.resolve(position: pos, proposed: next, radius: 0.45, walls: walls)
            node.position = SCNVector3(resolved.x, 0, resolved.z)
            node.eulerAngles.y = CGFloat(atan2(-dir.x, -dir.z))
            node.eulerAngles.x = CGFloat(sin(wander * 8) * 0.03)
        } else if len > 0.2 {
            node.eulerAngles.y = CGFloat(atan2(-dir.x, -dir.z))
        }

        if canShoot, now - lastShot > 0.4 + TimeInterval(id) * 0.05 {
            lastShot = now
            if shootPlayer { return .fireAtPlayer }
            if let shootBot { return .fireAtBot(shootBot.id) }
        }

        if isTerrorist, !bombPlanted, Collision.distanceXZ(pos, site) < GameRules.siteRadius {
            plantProgress += TimeInterval(dt)
            if plantProgress >= GameRules.plantTime { return .plant }
        } else {
            plantProgress = max(0, plantProgress - TimeInterval(dt) * 0.6)
        }
        return .idle
    }

    var xz: SIMD3<Float> {
        SIMD3(Float(node.position.x), Float(node.position.y), Float(node.position.z))
    }

    func takeDamage(_ amount: Int) {
        health = GameRules.remainingHealth(current: health, damage: amount)
        if !isAlive {
            node.runAction(.sequence([
                .rotateBy(x: 1.15, y: 0.15, z: 0.35, duration: 0.38),
                .fadeOut(duration: 0.3),
                .removeFromParentNode()
            ]))
        }
    }

    private func visible(from: SIMD3<Float>, to: SIMD3<Float>, world: SCNNode) -> Bool {
        guard Collision.distanceXZ(from, to) < 34 else { return false }
        let origin = SCNVector3(from.x, from.y + 1.5, from.z)
        let dest = SCNVector3(to.x, to.y + 1.4, to.z)
        let hits = world.hitTestWithSegment(from: origin, to: dest, options: [
            SCNHitTestOption.searchMode.rawValue: NSNumber(value: SCNHitTestSearchMode.closest.rawValue)
        ])
        guard let first = hits.first else { return true }
        var current: SCNNode? = first.node
        while let node = current {
            let name = node.name ?? ""
            if name == NodeName.player || name == NodeName.camera || name == "weaponRig" { return true }
            if name.hasPrefix(NodeName.terroristPrefix) || name.hasPrefix(NodeName.counterPrefix) { return true }
            current = node.parent
        }
        return false
    }
}

enum BotAction {
    case idle
    case fireAtPlayer
    case fireAtBot(Int)
    case plant
}
