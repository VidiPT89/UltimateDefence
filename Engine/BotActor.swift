import SceneKit
import AppKit
import simd

final class BotActor {
    let id: Int
    let node: SCNNode
    let head: SCNNode
    var health = GameRules.botMaxHealth
    var lastShot: TimeInterval = 0
    var plantProgress: TimeInterval = 0
    private var wander: Float
    private let leftLeg: SCNNode
    private let rightLeg: SCNNode

    var isAlive: Bool { health > 0 }

    init(id: Int, at spawn: SIMD3<Float>) {
        self.id = id
        wander = Float(id) * 0.7
        node = SCNNode()
        node.name = "\(NodeName.botPrefix)\(id)"
        node.position = SCNVector3(spawn.x, 0, spawn.z)

        let pants = NSColor(calibratedRed: 0.42, green: 0.36, blue: 0.26, alpha: 1)
        let jacket = NSColor(calibratedRed: 0.38, green: 0.40, blue: 0.34, alpha: 1)
        let skin = NSColor(calibratedRed: 0.76, green: 0.58, blue: 0.44, alpha: 1)
        let boot = NSColor(calibratedRed: 0.12, green: 0.10, blue: 0.08, alpha: 1)

        leftLeg = Self.box(0.16, 0.72, 0.18, at: SCNVector3(-0.12, 0.46, 0), color: pants)
        rightLeg = Self.box(0.16, 0.72, 0.18, at: SCNVector3(0.12, 0.46, 0), color: pants)
        node.addChildNode(leftLeg)
        node.addChildNode(rightLeg)
        node.addChildNode(Self.box(0.22, 0.12, 0.28, at: SCNVector3(-0.12, 0.08, 0.02), color: boot))
        node.addChildNode(Self.box(0.22, 0.12, 0.28, at: SCNVector3(0.12, 0.08, 0.02), color: boot))

        let hips = Self.box(0.42, 0.22, 0.24, at: SCNVector3(0, 0.92, 0), color: pants)
        node.addChildNode(hips)
        let torso = Self.box(0.46, 0.52, 0.28, at: SCNVector3(0, 1.28, 0), color: jacket)
        torso.name = "\(NodeName.botPrefix)\(id)"
        node.addChildNode(torso)

        let headGeom = SCNBox(width: 0.24, height: 0.28, length: 0.24, chamferRadius: 0)
        headGeom.firstMaterial = MapTextures.goldSrc(skin)
        head = SCNNode(geometry: headGeom)
        head.name = "\(NodeName.botPrefix)\(id)\(NodeName.headSuffix)"
        head.position = SCNVector3(0, 1.68, 0)
        node.addChildNode(head)

        let beanie = Self.box(0.26, 0.1, 0.26, at: SCNVector3(0, 0.16, 0), color: NSColor(calibratedRed: 0.18, green: 0.16, blue: 0.12, alpha: 1))
        head.addChildNode(beanie)
        let beard = Self.box(0.16, 0.08, 0.06, at: SCNVector3(0, -0.1, 0.12), color: NSColor(calibratedRed: 0.18, green: 0.12, blue: 0.08, alpha: 1))
        head.addChildNode(beard)

        node.addChildNode(Self.box(0.14, 0.5, 0.14, at: SCNVector3(-0.32, 1.22, 0.02), color: jacket))
        node.addChildNode(Self.box(0.14, 0.5, 0.14, at: SCNVector3(0.32, 1.22, 0.02), color: jacket))

        let rifle = Self.box(0.07, 0.08, 0.78, at: SCNVector3(0.28, 1.18, -0.28), color: NSColor(calibratedRed: 0.18, green: 0.16, blue: 0.12, alpha: 1))
        rifle.eulerAngles.x = -0.12
        node.addChildNode(rifle)
        node.addChildNode(Self.box(0.05, 0.18, 0.12, at: SCNVector3(0.28, 1.04, -0.12), color: NSColor(calibratedRed: 0.42, green: 0.26, blue: 0.12, alpha: 1)))

        let bodyShape = SCNBox(width: 0.55, height: 1.75, length: 0.4, chamferRadius: 0)
        node.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: bodyShape, options: nil))
        node.physicsBody?.categoryBitMask = PhysicsCategory.bot
        head.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: headGeom, options: nil))
        head.physicsBody?.categoryBitMask = PhysicsCategory.bot
    }

    func update(
        dt: Float,
        now: TimeInterval,
        player: PlayerController,
        site: SIMD3<Float>,
        walls: [AABB],
        bombPlanted: Bool,
        world: SCNNode
    ) -> BotAction {
        guard isAlive else { return .idle }
        let pos = SIMD3(Float(node.position.x), Float(node.position.y), Float(node.position.z))
        let playerPos = player.worldPosition
        let toPlayer = Collision.distanceXZ(pos, playerPos)
        let seesPlayer = toPlayer < 32 && player.isAlive && hasLineOfSight(from: pos, to: playerPos, world: world)

        let planter = id == 0
        let target: SIMD3<Float>
        if bombPlanted && seesPlayer {
            target = playerPos
        } else if seesPlayer && toPlayer < 14 {
            target = playerPos
        } else if planter {
            target = site
        } else if seesPlayer {
            target = playerPos
        } else {
            target = site
        }

        var dir = SIMD3(target.x - pos.x, 0, target.z - pos.z)
        let len = simd_length(dir)
        let holdingAngle = seesPlayer && toPlayer < 16
        if len > 0.55, !holdingAngle || toPlayer > 9 {
            dir /= len
            wander += dt * (seesPlayer ? 2.2 : 1.1)
            let side = SIMD3(-dir.z, 0, dir.x) * sin(wander) * (seesPlayer ? 0.85 : 0.4)
            let speed = GameRules.botSpeed * (plantProgress > 0 ? 0.3 : 1)
            let next = pos + (dir + side) * speed * dt
            let resolved = Collision.resolve(position: pos, proposed: next, radius: 0.45, walls: walls)
            node.position = SCNVector3(resolved.x, 0, resolved.z)
            node.eulerAngles.y = CGFloat(atan2(-dir.x, -dir.z))
            let swing = sin(wander * 8) * 0.18
            leftLeg.eulerAngles.x = CGFloat(swing)
            rightLeg.eulerAngles.x = CGFloat(-swing)
        } else if seesPlayer {
            node.eulerAngles.y = CGFloat(atan2(-(playerPos.x - pos.x), -(playerPos.z - pos.z)))
        }

        if seesPlayer, now - lastShot > TimeInterval(0.42) + TimeInterval(id) * 0.06 {
            lastShot = now
            return .shoot
        }

        if !bombPlanted && Collision.distanceXZ(pos, site) < GameRules.siteRadius {
            plantProgress += TimeInterval(dt)
            if plantProgress >= GameRules.plantTime {
                return .plant
            }
        } else {
            plantProgress = max(0, plantProgress - TimeInterval(dt) * 0.6)
        }
        return .idle
    }

    func takeDamage(_ amount: Int) {
        health = GameRules.remainingHealth(current: health, damage: amount)
        if !isAlive {
            node.physicsBody = nil
            head.physicsBody = nil
            let drop = SCNAction.rotateBy(x: 1.2, y: 0.2, z: 0.4, duration: 0.4)
            node.runAction(.sequence([
                .group([drop, .moveBy(x: 0, y: 0.1, z: 0, duration: 0.12)]),
                .fadeOut(duration: 0.35),
                .removeFromParentNode()
            ]))
        }
    }

    private func hasLineOfSight(from: SIMD3<Float>, to: SIMD3<Float>, world: SCNNode) -> Bool {
        let origin = SCNVector3(from.x, from.y + 1.5, from.z)
        let dest = SCNVector3(to.x, to.y, to.z)
        let hits = world.hitTestWithSegment(from: origin, to: dest, options: [
            SCNHitTestOption.searchMode.rawValue: SCNHitTestSearchMode.closest.rawValue
        ])
        guard let first = hits.first else { return true }
        var current: SCNNode? = first.node
        while let node = current {
            let name = node.name ?? ""
            if name == NodeName.player || name == NodeName.camera || name == "weaponRig" {
                return true
            }
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
    case shoot
    case plant
}
