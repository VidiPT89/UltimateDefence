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
    private let leftLeg: SCNNode
    private let rightLeg: SCNNode

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

        let pants = team == .terrorist
            ? NSColor(calibratedRed: 0.42, green: 0.34, blue: 0.22, alpha: 1)
            : NSColor(calibratedRed: 0.18, green: 0.22, blue: 0.3, alpha: 1)
        let jacket = team == .terrorist
            ? NSColor(calibratedRed: 0.48, green: 0.36, blue: 0.2, alpha: 1)
            : NSColor(calibratedRed: 0.22, green: 0.38, blue: 0.62, alpha: 1)
        let skin = NSColor(calibratedRed: 0.76, green: 0.58, blue: 0.44, alpha: 1)
        let boot = NSColor(calibratedRed: 0.1, green: 0.09, blue: 0.08, alpha: 1)

        leftLeg = Self.box(0.17, 0.74, 0.19, at: SCNVector3(-0.13, 0.48, 0), color: pants)
        rightLeg = Self.box(0.17, 0.74, 0.19, at: SCNVector3(0.13, 0.48, 0), color: pants)
        node.addChildNode(leftLeg)
        node.addChildNode(rightLeg)
        node.addChildNode(Self.box(0.22, 0.12, 0.3, at: SCNVector3(-0.13, 0.08, 0.02), color: boot))
        node.addChildNode(Self.box(0.22, 0.12, 0.3, at: SCNVector3(0.13, 0.08, 0.02), color: boot))
        node.addChildNode(Self.box(0.44, 0.22, 0.26, at: SCNVector3(0, 0.94, 0), color: pants))
        let torso = Self.box(0.48, 0.54, 0.3, at: SCNVector3(0, 1.3, 0), color: jacket)
        torso.name = "\(prefix)\(id)"
        node.addChildNode(torso)

        let headGeom = SCNBox(width: 0.24, height: 0.28, length: 0.24, chamferRadius: 0)
        headGeom.firstMaterial = MapTextures.goldSrc(skin)
        head = SCNNode(geometry: headGeom)
        head.name = "\(prefix)\(id)\(NodeName.headSuffix)"
        head.position = SCNVector3(0, 1.7, 0)
        node.addChildNode(head)
        let hatColor = team == .terrorist
            ? NSColor(calibratedRed: 0.16, green: 0.14, blue: 0.1, alpha: 1)
            : NSColor(calibratedRed: 0.12, green: 0.16, blue: 0.22, alpha: 1)
        head.addChildNode(Self.box(0.26, 0.1, 0.26, at: SCNVector3(0, 0.16, 0), color: hatColor))
        node.addChildNode(Self.box(0.15, 0.52, 0.15, at: SCNVector3(-0.34, 1.24, 0.02), color: jacket))
        node.addChildNode(Self.box(0.15, 0.52, 0.15, at: SCNVector3(0.34, 1.24, 0.02), color: jacket))
        let rifle = Self.box(0.07, 0.08, 0.8, at: SCNVector3(0.3, 1.2, -0.3), color: NSColor(calibratedRed: 0.16, green: 0.15, blue: 0.12, alpha: 1))
        rifle.eulerAngles.x = -0.12
        node.addChildNode(rifle)
    }

    func update(
        dt: Float,
        now: TimeInterval,
        player: PlayerController,
        allies: [BotActor],
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
            let swing = sin(wander * 8) * 0.18
            leftLeg.eulerAngles.x = CGFloat(swing)
            rightLeg.eulerAngles.x = CGFloat(-swing)
        } else if len > 0.2 {
            node.eulerAngles.y = CGFloat(atan2(-dir.x, -dir.z))
        }

        if canShoot, now - lastShot > 0.4 + TimeInterval(id) * 0.05 {
            lastShot = now
            if shootPlayer { return .fireAtPlayer }
            if let shootBot { return .fireAtBot(shootBot.id) }
        }

        if isTerrorist, id == 0, !bombPlanted, Collision.distanceXZ(pos, site) < GameRules.siteRadius {
            plantProgress += TimeInterval(dt)
            if plantProgress >= GameRules.plantTime { return .plant }
        } else {
            plantProgress = max(0, plantProgress - TimeInterval(dt) * 0.6)
        }
        _ = allies
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
            SCNHitTestOption.searchMode.rawValue: SCNHitTestSearchMode.closest.rawValue
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

    private static func box(_ w: CGFloat, _ h: CGFloat, _ l: CGFloat, at: SCNVector3, color: NSColor) -> SCNNode {
        let g = SCNBox(width: w, height: h, length: l, chamferRadius: 0)
        g.firstMaterial = MapTextures.goldSrc(color)
        let n = SCNNode(geometry: g)
        n.position = at
        return n
    }
}

enum BotAction {
    case idle
    case fireAtPlayer
    case fireAtBot(Int)
    case plant
}
