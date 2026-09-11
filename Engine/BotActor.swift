import SceneKit
import AppKit
import simd

final class BotActor {
    let id: Int
    let team: BotTeam
    let node: SCNNode
    var health = GameRules.botMaxHealth
    var lastShot: TimeInterval = 0
    var plantProgress: TimeInterval = 0
    private let path: [SIMD3<Float>]
    private let rush: Bool
    private var waypoint = 0
    private var burstLeft = 0

    var isAlive: Bool { health > 0 }
    var isTerrorist: Bool { team == .terrorist }

    init(id: Int, team: BotTeam, at spawn: SIMD3<Float>, path: [SIMD3<Float>]) {
        self.id = id
        self.team = team
        self.path = path.isEmpty ? [spawn] : path
        rush = id % 2 == 0
        let prefix = team == .terrorist ? NodeName.terroristPrefix : NodeName.counterPrefix
        node = SCNNode()
        node.name = "\(prefix)\(id)"
        node.position = SCNVector3(spawn.x, 0, spawn.z)
        CharacterMesh.attach(
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
        idleAim: SIMD3<Float>,
        walls: [AABB],
        bombPlanted: Bool,
        planterId: Int,
        others: [BotActor]
    ) -> BotAction {
        guard isAlive else { return .idle }
        let pos = SIMD3(Float(node.position.x), 0, Float(node.position.z))
        var target: BotActor?
        var shootPlayer = false
        var aim = goal(from: pos, site: site, bombPlanted: bombPlanted, planterId: planterId, idleAim: idleAim)

        if isTerrorist, player.isAlive, visible(from: pos, to: player.worldPosition, walls: walls) {
            aim = player.worldPosition
            shootPlayer = true
        } else if let enemy = nearestVisible(from: pos, enemies: enemies, walls: walls) {
            aim = enemy.xz
            target = enemy
        }

        let fighting = shootPlayer || target != nil
        if !fighting {
            walk(
                from: pos,
                toward: goal(from: pos, site: site, bombPlanted: bombPlanted, planterId: planterId, idleAim: idleAim),
                dt: dt,
                walls: walls,
                others: others,
                slow: plantProgress > 0.2
            )
            face(isTerrorist ? goal(from: pos, site: site, bombPlanted: bombPlanted, planterId: planterId, idleAim: idleAim) : idleAim)
        } else {
            face(aim)
        }

        let onSite = Collision.distanceXZ(pos, site) < GameRules.siteRadius
        if GameRules.canPlant(isTerrorist: isTerrorist, botId: id, planterId: planterId, planted: bombPlanted, onSite: onSite) {
            plantProgress += TimeInterval(dt)
            if plantProgress >= GameRules.plantTime { return .plant }
        } else {
            plantProgress = 0
        }

        if fighting {
            return fireIfReady(now: now, shootPlayer: shootPlayer, shootBot: target)
        }
        burstLeft = 0
        return .idle
    }

    var xz: SIMD3<Float> {
        SIMD3(Float(node.position.x), 0, Float(node.position.z))
    }

    func takeDamage(_ amount: Int) {
        health = GameRules.remainingHealth(current: health, damage: amount)
        if !isAlive {
            node.runAction(.sequence([
                .rotateBy(x: 1.1, y: 0.1, z: 0.3, duration: 0.35),
                .fadeOut(duration: 0.28),
                .removeFromParentNode()
            ]))
        }
    }

    private func goal(
        from pos: SIMD3<Float>,
        site: SIMD3<Float>,
        bombPlanted: Bool,
        planterId: Int,
        idleAim: SIMD3<Float>
    ) -> SIMD3<Float> {
        if bombPlanted {
            return isTerrorist ? site : site
        }
        while waypoint < path.count, Collision.distanceXZ(pos, path[waypoint]) < 0.95 {
            waypoint += 1
        }
        if waypoint >= path.count {
            if isTerrorist, id == planterId {
                return site
            }
            if isTerrorist {
                return path.last ?? site
            }
            return path.last ?? idleAim
        }
        return path[waypoint]
    }

    private func walk(
        from pos: SIMD3<Float>,
        toward look: SIMD3<Float>,
        dt: Float,
        walls: [AABB],
        others: [BotActor],
        slow: Bool
    ) {
        var dir = SIMD3(look.x - pos.x, 0, look.z - pos.z)
        let len = simd_length(dir)
        guard len > 0.35 else { return }
        dir /= len
        var speed = GameRules.botSpeed * (rush ? 1.05 : 0.92)
        if slow { speed *= 0.28 }
        var next = pos + dir * speed * dt
        for other in others where other.id != id && other.isAlive && other.team == team {
            let gap = Collision.distanceXZ(next, other.xz)
            if gap < 0.8, gap > 0.01 {
                next += (next - other.xz) / gap * (0.8 - gap)
            }
        }
        let resolved = Collision.resolve(position: pos, proposed: next, radius: 0.42, walls: walls)
        node.position = SCNVector3(resolved.x, 0, resolved.z)
    }

    private func face(_ look: SIMD3<Float>) {
        let pos = xz
        let dir = SIMD3(look.x - pos.x, 0, look.z - pos.z)
        guard simd_length(dir) > 0.08 else { return }
        node.eulerAngles.y = CGFloat(atan2(-dir.x, -dir.z))
    }

    private func nearestVisible(from: SIMD3<Float>, enemies: [BotActor], walls: [AABB]) -> BotActor? {
        enemies
            .filter { $0.isAlive && visible(from: from, to: $0.xz, walls: walls) }
            .min { Collision.distanceXZ(from, $0.xz) < Collision.distanceXZ(from, $1.xz) }
    }

    private func fireIfReady(now: TimeInterval, shootPlayer: Bool, shootBot: BotActor?) -> BotAction {
        let gap: TimeInterval = burstLeft > 0 ? 0.1 : 0.42
        guard now - lastShot > gap else { return .idle }
        if burstLeft <= 0 { burstLeft = 4 }
        burstLeft -= 1
        lastShot = now
        if shootPlayer { return .fireAtPlayer }
        if let shootBot { return .fireAtBot(shootBot.id) }
        return .idle
    }

    private func visible(from: SIMD3<Float>, to: SIMD3<Float>, walls: [AABB]) -> Bool {
        let dist = Collision.distanceXZ(from, to)
        guard dist < 28 else { return false }
        return Collision.losClear(from, to, walls: walls)
    }
}

enum BotAction {
    case idle
    case fireAtPlayer
    case fireAtBot(Int)
    case plant
}
