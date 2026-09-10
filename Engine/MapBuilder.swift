import SceneKit
import AppKit

enum PhysicsCategory {
    static let world: Int = 1 << 0
    static let bot: Int = 1 << 1
}

enum NodeName {
    static let player = "player"
    static let camera = "fpsCamera"
    static let site = "siteA"
    static let botPrefix = "bot-"
    static let headSuffix = "-head"
}

struct MapLayout {
    let walls: [AABB]
    let siteCenter: SIMD3<Float>
    let playerSpawn: SIMD3<Float>
    let attackerSpawns: [SIMD3<Float>]
}

enum MapBuilder {
    static func make() -> (SCNScene, MapLayout) {
        let scene = SCNScene()
        scene.background.contents = NSColor(calibratedRed: 0.10, green: 0.08, blue: 0.07, alpha: 1)
        scene.fogStartDistance = 22
        scene.fogEndDistance = 78
        scene.fogColor = NSColor(calibratedRed: 0.16, green: 0.11, blue: 0.08, alpha: 1)
        scene.lightingEnvironment.contents = NSColor(calibratedRed: 0.35, green: 0.22, blue: 0.14, alpha: 1)
        scene.lightingEnvironment.intensity = 0.8

        addLights(to: scene)
        scene.rootNode.addParticleSystem(FX.dustField())

        let floor = SCNNode(geometry: SCNFloor())
        floor.geometry?.firstMaterial = pbr(
            NSColor(calibratedRed: 0.16, green: 0.15, blue: 0.13, alpha: 1),
            metal: 0.05,
            rough: 0.92
        )
        if let floorGeom = floor.geometry as? SCNFloor {
            floorGeom.reflectivity = 0.04
        }
        floor.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        floor.physicsBody?.categoryBitMask = PhysicsCategory.world
        scene.rootNode.addChildNode(floor)

        var walls: [AABB] = []
        func wall(x: Float, z: Float, w: Float, d: Float, h: Float = 4.4, color: NSColor, metal: CGFloat = 0.08) {
            let box = SCNBox(width: CGFloat(w), height: CGFloat(h), length: CGFloat(d), chamferRadius: 0.04)
            box.firstMaterial = pbr(color, metal: metal, rough: 0.62)
            let node = SCNNode(geometry: box)
            node.position = SCNVector3(x, h / 2, z)
            node.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: box, options: nil))
            node.physicsBody?.categoryBitMask = PhysicsCategory.world
            scene.rootNode.addChildNode(node)
            walls.append(AABB(minX: x - w / 2, maxX: x + w / 2, minZ: z - d / 2, maxZ: z + d / 2))
        }

        let concrete = NSColor(calibratedRed: 0.28, green: 0.27, blue: 0.24, alpha: 1)
        let rust = NSColor(calibratedRed: 0.42, green: 0.22, blue: 0.12, alpha: 1)
        let crate = NSColor(calibratedRed: 0.36, green: 0.27, blue: 0.14, alpha: 1)

        wall(x: 0, z: -32, w: 64, d: 1.2, color: concrete, metal: 0.2)
        wall(x: 0, z: 32, w: 64, d: 1.2, color: concrete, metal: 0.2)
        wall(x: -32, z: 0, w: 1.2, d: 64, color: concrete, metal: 0.2)
        wall(x: 32, z: 0, w: 1.2, d: 64, color: concrete, metal: 0.2)

        wall(x: -12, z: -8, w: 14, d: 1.4, color: rust)
        wall(x: 8, z: 6, w: 1.4, d: 18, color: rust)
        wall(x: -4, z: 14, w: 16, d: 1.4, color: rust)
        wall(x: 16, z: -14, w: 10, d: 1.4, color: rust)
        wall(x: -18, z: 4, w: 1.4, d: 12, color: rust)

        wall(x: 18, z: 18, w: 3, d: 3, h: 2.2, color: crate)
        wall(x: 22, z: 16, w: 2.4, d: 2.4, h: 1.6, color: crate)
        wall(x: -20, z: -18, w: 3.2, d: 2.8, h: 2.0, color: crate)
        wall(x: 4, z: -20, w: 2.6, d: 2.6, h: 1.8, color: crate)
        wall(x: -8, z: 20, w: 2.8, d: 2.4, h: 1.7, color: crate)

        addLamps(to: scene, at: [SIMD3(0, 5.2, 0), SIMD3(14, 5.2, -10), SIMD3(-16, 5.2, 10), SIMD3(-20, 4.6, 20)])

        let siteCenter = SIMD3<Float>(-22, 0, 22)
        addSite(to: scene, center: siteCenter)

        let layout = MapLayout(
            walls: walls,
            siteCenter: siteCenter,
            playerSpawn: SIMD3<Float>(20, 1.6, -22),
            attackerSpawns: [
                SIMD3<Float>(-22, 1.5, -22),
                SIMD3<Float>(-18, 1.5, -24),
                SIMD3<Float>(-26, 1.5, -20),
                SIMD3<Float>(-14, 1.5, -22)
            ]
        )
        return (scene, layout)
    }

    private static func addSite(to scene: SCNScene, center: SIMD3<Float>) {
        let pad = SCNCylinder(radius: 4.5, height: 0.06)
        pad.firstMaterial = pbr(NSColor(calibratedRed: 0.55, green: 0.14, blue: 0.08, alpha: 1), metal: 0.3, rough: 0.4)
        pad.firstMaterial?.emission.contents = NSColor(calibratedRed: 0.95, green: 0.28, blue: 0.08, alpha: 1)
        pad.firstMaterial?.emission.intensity = 0.45
        let siteNode = SCNNode(geometry: pad)
        siteNode.name = NodeName.site
        siteNode.position = SCNVector3(center.x, 0.04, center.z)
        scene.rootNode.addChildNode(siteNode)

        let ring = SCNTorus(ringRadius: 4.2, pipeRadius: 0.045)
        ring.firstMaterial = emissive(NSColor(calibratedRed: 1, green: 0.45, blue: 0.12, alpha: 1))
        let ringNode = SCNNode(geometry: ring)
        ringNode.position = SCNVector3(center.x, 0.12, center.z)
        ringNode.runAction(.repeatForever(.rotateBy(x: 0, y: 2.2, z: 0, duration: 6)))
        scene.rootNode.addChildNode(ringNode)

        let beacon = SCNCylinder(radius: 0.09, height: 2.8)
        beacon.firstMaterial = emissive(NSColor(calibratedRed: 1, green: 0.38, blue: 0.1, alpha: 1))
        let beaconNode = SCNNode(geometry: beacon)
        beaconNode.position = SCNVector3(center.x, 1.4, center.z)
        let pulse = SCNAction.sequence([
            .customAction(duration: 0.8) { node, t in
                node.geometry?.firstMaterial?.emission.intensity = 0.4 + Double(t) * 1.4
            },
            .customAction(duration: 0.8) { node, t in
                node.geometry?.firstMaterial?.emission.intensity = 1.8 - Double(t) * 1.4
            }
        ])
        beaconNode.runAction(.repeatForever(pulse))
        scene.rootNode.addChildNode(beaconNode)

        let light = SCNNode()
        light.light = SCNLight()
        light.light?.type = .omni
        light.light?.color = NSColor(calibratedRed: 1, green: 0.4, blue: 0.12, alpha: 1)
        light.light?.intensity = 420
        light.light?.attenuationEndDistance = 16
        light.position = SCNVector3(center.x, 3.2, center.z)
        scene.rootNode.addChildNode(light)
    }

    private static func addLamps(to scene: SCNScene, at points: [SIMD3<Float>]) {
        for p in points {
            let housing = SCNBox(width: 0.7, height: 0.12, length: 0.7, chamferRadius: 0.02)
            housing.firstMaterial = pbr(NSColor(calibratedWhite: 0.12, alpha: 1), metal: 0.8, rough: 0.25)
            let lamp = SCNNode(geometry: housing)
            lamp.position = SCNVector3(p.x, p.y, p.z)
            scene.rootNode.addChildNode(lamp)

            let bulb = SCNNode()
            bulb.light = SCNLight()
            bulb.light?.type = .spot
            bulb.light?.spotInnerAngle = 40
            bulb.light?.spotOuterAngle = 78
            bulb.light?.color = NSColor(calibratedRed: 1, green: 0.86, blue: 0.62, alpha: 1)
            bulb.light?.intensity = 900
            bulb.light?.castsShadow = true
            bulb.eulerAngles = SCNVector3(-CGFloat.pi / 2, 0, 0)
            bulb.position = SCNVector3(p.x, p.y - 0.2, p.z)
            scene.rootNode.addChildNode(bulb)
        }
    }

    private static func addLights(to scene: SCNScene) {
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 180
        ambient.light?.color = NSColor(calibratedRed: 0.55, green: 0.48, blue: 0.42, alpha: 1)
        scene.rootNode.addChildNode(ambient)

        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.intensity = 520
        sun.light?.color = NSColor(calibratedRed: 1, green: 0.78, blue: 0.55, alpha: 1)
        sun.light?.castsShadow = true
        sun.light?.shadowSampleCount = 8
        sun.eulerAngles = SCNVector3(-0.85, 0.55, 0)
        scene.rootNode.addChildNode(sun)
    }

    private static func pbr(_ color: NSColor, metal: CGFloat, rough: CGFloat) -> SCNMaterial {
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = color
        mat.metalness.contents = metal
        mat.roughness.contents = rough
        return mat
    }

    private static func emissive(_ color: NSColor) -> SCNMaterial {
        let mat = SCNMaterial()
        mat.lightingModel = .constant
        mat.diffuse.contents = color
        mat.emission.contents = color
        mat.emission.intensity = 1.1
        return mat
    }
}
