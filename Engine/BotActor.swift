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

    var isAlive: Bool { health > 0 }

    init(id: Int, at spawn: SIMD3<Float>) {
        self.id = id
        wander = Float(id) * 0.7
        let body = SCNCapsule(capRadius: 0.38, height: 1.5)
        body.firstMaterial = Self.pbr(NSColor(calibratedRed: 0.18, green: 0.19, blue: 0.2, alpha: 1), metal: 0.35, rough: 0.45)
        node = SCNNode(geometry: body)
        node.name = "\(NodeName.botPrefix)\(id)"
        node.position = SCNVector3(spawn.x, 1.15, spawn.z)

        let vest = SCNBox(width: 0.72, height: 0.55, length: 0.42, chamferRadius: 0.04)
        vest.firstMaterial = Self.pbr(NSColor(calibratedRed: 0.72, green: 0.28, blue: 0.12, alpha: 1), metal: 0.15, rough: 0.55)
        let vestNode = SCNNode(geometry: vest)
        vestNode.position = SCNVector3(0, 0.15, 0)
        node.addChildNode(vestNode)

        let headGeom = SCNSphere(radius: 0.22)
        headGeom.firstMaterial = Self.pbr(NSColor(calibratedRed: 0.78, green: 0.58, blue: 0.46, alpha: 1), metal: 0.05, rough: 0.7)
        head = SCNNode(geometry: headGeom)
        head.name = "\(NodeName.botPrefix)\(id)\(NodeName.headSuffix)"
        let visor = SCNBox(width: 0.38, height: 0.12, length: 0.18, chamferRadius: 0.02)
        visor.firstMaterial = Self.pbr(NSColor(calibratedRed: 0.98, green: 0.45, blue: 0.08, alpha: 1), metal: 0.8, rough: 0.18)
        visor.firstMaterial?.emission.contents = NSColor(calibratedRed: 0.98, green: 0.61, blue: 0, alpha: 1)
        visor.firstMaterial?.emission.intensity = 0.6
        let visorNode = SCNNode(geometry: visor)
        visorNode.position = SCNVector3(0, 0.04, 0.16)
        head.addChildNode(visorNode)
        head.position = SCNVector3(0, 0.95, 0)
        node.addChildNode(head)

        let rifle = SCNBox(width: 0.08, height: 0.08, length: 0.72, chamferRadius: 0.01)
        rifle.firstMaterial = Self.pbr(NSColor(calibratedRed: 0.22, green: 0.23, blue: 0.24, alpha: 1), metal: 0.7, rough: 0.28)
        let rifleNode = SCNNode(geometry: rifle)
        rifleNode.position = SCNVector3(0.32, 0.22, -0.28)
        node.addChildNode(rifleNode)

        let shape = SCNPhysicsShape(geometry: body, options: nil)
        node.physicsBody = SCNPhysicsBody(type: .kinematic, shape: shape)
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
        let seesPlayer = toPlayer < 28 && player.isAlive && hasLineOfSight(from: pos, to: playerPos, world: world)

        let planter = id == 0
        let target: SIMD3<Float>
        if bombPlanted {
            target = playerPos
        } else if planter && toPlayer > 10 {
            target = site
        } else if seesPlayer && toPlayer < 18 {
            target = playerPos
        } else if planter {
            target = site
        } else {
            target = site
        }

        var dir = SIMD3(target.x - pos.x, 0, target.z - pos.z)
        let len = simd_length(dir)
        if len > 0.4 {
            dir /= len
            wander += dt
            let side = SIMD3(-dir.z, 0, dir.x) * sin(wander * (seesPlayer ? 2.4 : 1)) * (seesPlayer ? 0.7 : 0.35)
            let speed = GameRules.botSpeed * (plantProgress > 0 ? 0.35 : 1)
            let next = pos + (dir + side) * speed * dt
            let resolved = Collision.resolve(position: pos, proposed: next, radius: 0.5, walls: walls)
            node.position = SCNVector3(resolved.x, resolved.y, resolved.z)
            node.eulerAngles.y = CGFloat(atan2(-dir.x, -dir.z))
        }

        if seesPlayer, now - lastShot > TimeInterval(0.48) + TimeInterval(id) * 0.05 {
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
            let drop = SCNAction.moveBy(x: 0, y: -0.9, z: 0, duration: 0.45)
            drop.timingMode = .easeIn
            node.runAction(.sequence([
                .group([drop, .fadeOut(duration: 0.45)]),
                .removeFromParentNode()
            ]))
        }
    }

    private func hasLineOfSight(from: SIMD3<Float>, to: SIMD3<Float>, world: SCNNode) -> Bool {
        let origin = SCNVector3(from.x, from.y + 0.4, from.z)
        let dest = SCNVector3(to.x, to.y, to.z)
        let hits = world.hitTestWithSegment(from: origin, to: dest, options: [
            SCNHitTestOption.searchMode.rawValue: SCNHitTestSearchMode.closest.rawValue
        ])
        guard let first = hits.first else { return true }
        let name = first.node.name ?? first.node.parent?.name ?? ""
        return name == NodeName.player || name == NodeName.camera || name == "weaponRig"
    }

    private static func pbr(_ color: NSColor, metal: CGFloat, rough: CGFloat) -> SCNMaterial {
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = color
        mat.metalness.contents = metal
        mat.roughness.contents = rough
        return mat
    }
}

enum BotAction {
    case idle
    case shoot
    case plant
}
