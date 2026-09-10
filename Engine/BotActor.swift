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
    private let path: [SIMD3<Float>]
    private var waypoint = 0

    var isAlive: Bool { health > 0 }
    var isTerrorist: Bool { team == .terrorist }

    init(id: Int, team: BotTeam, at spawn: SIMD3<Float>, path: [SIMD3<Float>]) {
        self.id = id
        self.team = team
        self.path = path.isEmpty ? [spawn] : path
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
        planterId: Int,
        others: [BotActor]
    ) -> BotAction {
        guard isAlive else { return .idle }
        let pos = SIMD3(Float(node.position.x), 0, Float(node.position.z))
        let playerPos = player.worldPosition
        var look = destination(from: pos, site: site, bombPlanted: bombPlanted, planterId: planterId)
        var canShoot = false
        var shootPlayer = false
        var shootBot: BotActor?

        if isTerrorist, player.isAlive, visible(from: pos, to: playerPos, walls: walls) {
            look = playerPos
            canShoot = true
            shootPlayer = true
        } else if let enemy = enemies.first(where: { $0.isAlive && visible(from: pos, to: $0.xz, walls: walls) }) {
            look = enemy.xz
            canShoot = true
            shootBot = enemy
        }

        var dir = SIMD3(look.x - pos.x, 0, look.z - pos.z)
        let len = simd_length(dir)
        let hold = canShoot && len < 11
        if len > 0.55, !hold {
            dir /= len
            var next = pos + dir * GameRules.botSpeed * (plantProgress > 0 ? 0.25 : 1) * dt
            for other in others where other.id != id && other.isAlive && other.team == team {
                let gap = Collision.distanceXZ(next, other.xz)
                if gap < 0.9, gap > 0.01 {
                    next += (next - other.xz) / gap * (0.9 - gap)
                }
            }
            let resolved = Collision.resolve(position: pos, proposed: next, radius: 0.42, walls: walls)
            node.position = SCNVector3(resolved.x, 0, resolved.z)
            node.eulerAngles.y = CGFloat(atan2(-dir.x, -dir.z))
        } else if len > 0.15 {
            node.eulerAngles.y = CGFloat(atan2(-dir.x, -dir.z))
        }

        if canShoot, now - lastShot > 0.45 + TimeInterval(id) * 0.04 {
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

    private func destination(from pos: SIMD3<Float>, site: SIMD3<Float>, bombPlanted: Bool, planterId: Int) -> SIMD3<Float> {
        if isTerrorist, id == planterId, !bombPlanted, waypoint >= path.count - 1 {
            return site
        }
        while waypoint < path.count, Collision.distanceXZ(pos, path[waypoint]) < 1.4 {
            waypoint += 1
        }
        if waypoint >= path.count {
            return path.last ?? site
        }
        return path[waypoint]
    }

    private func visible(from: SIMD3<Float>, to: SIMD3<Float>, walls: [AABB]) -> Bool {
        guard Collision.distanceXZ(from, to) < 32 else { return false }
        return Collision.losClear(from, to, walls: walls)
    }
}

enum BotAction {
    case idle
    case fireAtPlayer
    case fireAtBot(Int)
    case plant
}
