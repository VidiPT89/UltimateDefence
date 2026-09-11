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
    private let role: Role
    private var waypoint = 0
    private var born: TimeInterval = 0
    private var strafeSign: Float = 1
    private var strafeFlip: TimeInterval = 0
    private var burstLeft = 0
    private var pauseUntil: TimeInterval = 0

    var isAlive: Bool { health > 0 }
    var isTerrorist: Bool { team == .terrorist }

    private enum Role { case rush, lurk, hold }

    init(id: Int, team: BotTeam, at spawn: SIMD3<Float>, path: [SIMD3<Float>]) {
        self.id = id
        self.team = team
        self.path = path.isEmpty ? [spawn] : path
        if team == .terrorist {
            role = id % 3 == 0 ? .lurk : .rush
        } else {
            role = id % 3 == 0 ? .rush : .hold
        }
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
        rotatePoint: SIMD3<Float>,
        walls: [AABB],
        bombPlanted: Bool,
        planterId: Int,
        others: [BotActor]
    ) -> BotAction {
        guard isAlive else { return .idle }
        if born == 0 { born = now }
        let pos = SIMD3(Float(node.position.x), 0, Float(node.position.z))
        var look = destination(
            from: pos,
            now: now,
            site: site,
            rotatePoint: rotatePoint,
            bombPlanted: bombPlanted,
            planterId: planterId
        )
        var canShoot = false
        var shootPlayer = false
        var shootBot: BotActor?

        if isTerrorist, player.isAlive, visible(from: pos, to: player.worldPosition, walls: walls) {
            look = player.worldPosition
            canShoot = true
            shootPlayer = true
        } else if let enemy = enemies.first(where: { $0.isAlive && visible(from: pos, to: $0.xz, walls: walls) }) {
            look = enemy.xz
            canShoot = true
            shootBot = enemy
        }

        if now > strafeFlip {
            strafeSign *= -1
            strafeFlip = now + TimeInterval(0.28 + Float(id % 3) * 0.11)
        }

        advance(
            from: pos,
            toward: look,
            dt: dt,
            fighting: canShoot,
            walls: walls,
            others: others
        )

        let onSite = Collision.distanceXZ(pos, site) < GameRules.siteRadius
        if GameRules.canPlant(isTerrorist: isTerrorist, botId: id, planterId: planterId, planted: bombPlanted, onSite: onSite) {
            plantProgress += TimeInterval(dt) * (canShoot ? 0.55 : 1)
            if plantProgress >= GameRules.plantTime { return .plant }
        } else {
            plantProgress = max(0, plantProgress - TimeInterval(dt) * 0.6)
        }

        if canShoot {
            return fireIfReady(now: now, shootPlayer: shootPlayer, shootBot: shootBot)
        }
        burstLeft = 0
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

    private func destination(
        from pos: SIMD3<Float>,
        now: TimeInterval,
        site: SIMD3<Float>,
        rotatePoint: SIMD3<Float>,
        bombPlanted: Bool,
        planterId: Int
    ) -> SIMD3<Float> {
        let wobble = roam(now)
        if bombPlanted {
            return isTerrorist ? site + wobble * 0.7 : site
        }
        if isTerrorist, role == .lurk, now - born < 0.35 + TimeInterval(id) * 0.12 {
            return pos
        }
        while waypoint < path.count, Collision.distanceXZ(pos, path[waypoint]) < 1.5 {
            if role == .lurk, waypoint == 1, pauseUntil == 0 {
                pauseUntil = now + 1.2
            }
            if pauseUntil > now {
                return path[waypoint] + wobble
            }
            waypoint += 1
            pauseUntil = 0
        }
        if waypoint >= path.count {
            if isTerrorist {
                return site + wobble
            }
            if role == .rush, now - born > 7 {
                return rotatePoint + wobble
            }
            return (path.last ?? site) + wobble
        }
        if isTerrorist, id == planterId, waypoint >= path.count - 1 {
            return site
        }
        return path[waypoint]
    }

    private func roam(_ now: TimeInterval) -> SIMD3<Float> {
        let t = Float(now) * (role == .hold ? 0.85 : 1.6) + Float(id) * 1.7
        let radius: Float = role == .hold ? 1.5 : 2.2
        return SIMD3(cos(t) * radius, 0, sin(t * 0.73) * radius)
    }

    private func advance(
        from pos: SIMD3<Float>,
        toward look: SIMD3<Float>,
        dt: Float,
        fighting: Bool,
        walls: [AABB],
        others: [BotActor]
    ) {
        var dir = SIMD3(look.x - pos.x, 0, look.z - pos.z)
        let len = simd_length(dir)
        let planting = plantProgress > 0.15
        if len < 0.28, !fighting {
            node.eulerAngles.y = CGFloat(atan2(-dir.x, -dir.z))
            return
        }
        if len > 0.001 {
            dir /= len
        }
        if fighting {
            let side = SIMD3(-dir.z, 0, dir.x) * strafeSign
            let push: Float = isTerrorist && role == .rush ? 0.45 : 0.12
            dir = simd_normalize(dir * push + side * 0.95)
        }
        var speed = GameRules.botSpeed
        if role == .rush { speed *= 1.08 }
        if role == .lurk { speed *= 0.9 }
        if planting { speed *= 0.3 }
        if fighting, role == .hold { speed *= 0.72 }
        var next = pos + dir * speed * dt
        for other in others where other.id != id && other.isAlive && other.team == team {
            let gap = Collision.distanceXZ(next, other.xz)
            if gap < 0.85, gap > 0.01 {
                next += (next - other.xz) / gap * (0.85 - gap)
            }
        }
        var resolved = Collision.resolve(position: pos, proposed: next, radius: 0.42, walls: walls)
        if Collision.distanceXZ(resolved, pos) < 0.01, !planting {
            let side = SIMD3(-dir.z, 0, dir.x) * strafeSign
            let bump = pos + side * speed * dt
            resolved = Collision.resolve(position: pos, proposed: bump, radius: 0.42, walls: walls)
        }
        node.position = SCNVector3(resolved.x, 0, resolved.z)
        let face = fighting || len > 0.15 ? dir : SIMD3(look.x - pos.x, 0, look.z - pos.z)
        if simd_length(face) > 0.05 {
            node.eulerAngles.y = CGFloat(atan2(-face.x, -face.z))
        }
    }

    private func fireIfReady(now: TimeInterval, shootPlayer: Bool, shootBot: BotActor?) -> BotAction {
        let gap: TimeInterval = burstLeft > 0 ? 0.09 : 0.34 + TimeInterval(id % 3) * 0.04
        guard now - lastShot > gap else { return .idle }
        if burstLeft <= 0 {
            burstLeft = role == .hold ? 3 : 5
        }
        burstLeft -= 1
        lastShot = now
        if shootPlayer { return .fireAtPlayer }
        if let shootBot { return .fireAtBot(shootBot.id) }
        return .idle
    }

    private func visible(from: SIMD3<Float>, to: SIMD3<Float>, walls: [AABB]) -> Bool {
        guard Collision.distanceXZ(from, to) < 36 else { return false }
        return Collision.losClear(from, to, walls: walls)
    }
}

enum BotAction {
    case idle
    case fireAtPlayer
    case fireAtBot(Int)
    case plant
}
