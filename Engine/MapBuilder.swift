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
        let sky = NSColor(calibratedRed: 0.55, green: 0.72, blue: 0.88, alpha: 1)
        scene.background.contents = sky
        scene.fogStartDistance = 40
        scene.fogEndDistance = 95
        scene.fogColor = NSColor(calibratedRed: 0.62, green: 0.68, blue: 0.72, alpha: 1)

        addSky(to: scene)
        addLights(to: scene)
        scene.rootNode.addParticleSystem(FX.dustField())

        let floor = SCNNode(geometry: SCNFloor())
        floor.geometry?.firstMaterial = MapTextures.goldSrc(MapTextures.sand)
        if let floorGeom = floor.geometry as? SCNFloor {
            floorGeom.reflectivity = 0
        }
        floor.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        floor.physicsBody?.categoryBitMask = PhysicsCategory.world
        scene.rootNode.addChildNode(floor)

        var walls: [AABB] = []
        func wall(x: Float, z: Float, w: Float, d: Float, h: Float = 4.8, texture: NSImage) {
            let box = SCNBox(width: CGFloat(w), height: CGFloat(h), length: CGFloat(d), chamferRadius: 0)
            box.firstMaterial = MapTextures.goldSrc(texture)
            box.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(max(1, CGFloat(w / 2)), max(1, CGFloat(h / 2)), 1)
            let node = SCNNode(geometry: box)
            node.position = SCNVector3(x, h / 2, z)
            node.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: box, options: nil))
            node.physicsBody?.categoryBitMask = PhysicsCategory.world
            scene.rootNode.addChildNode(node)
            walls.append(AABB(minX: x - w / 2, maxX: x + w / 2, minZ: z - d / 2, maxZ: z + d / 2))
        }

        wall(x: 0, z: -32, w: 64, d: 1.4, texture: MapTextures.sandstone)
        wall(x: 0, z: 32, w: 64, d: 1.4, texture: MapTextures.sandstone)
        wall(x: -32, z: 0, w: 1.4, d: 64, texture: MapTextures.sandstone)
        wall(x: 32, z: 0, w: 1.4, d: 64, texture: MapTextures.sandstone)

        wall(x: -12, z: -8, w: 14, d: 1.6, texture: MapTextures.sandstone)
        wall(x: 8, z: 6, w: 1.6, d: 18, texture: MapTextures.sandstone)
        wall(x: -4, z: 14, w: 16, d: 1.6, texture: MapTextures.sandstone)
        wall(x: 16, z: -14, w: 10, d: 1.6, texture: MapTextures.sandstone)
        wall(x: -18, z: 4, w: 1.6, d: 12, texture: MapTextures.sandstone)
        wall(x: 10, z: -4, w: 8, d: 1.4, h: 3.2, texture: MapTextures.concrete)

        addCrate(to: scene, x: 18, z: 18, w: 1.6, h: 1.6, d: 1.6, walls: &walls)
        addCrate(to: scene, x: 19.7, z: 18, w: 1.6, h: 1.6, d: 1.6, walls: &walls)
        addCrate(to: scene, x: 18.8, z: 18, w: 1.6, h: 1.6, d: 1.6, y: 1.6, walls: &walls)
        addCrate(to: scene, x: 22, z: 16, w: 1.4, h: 1.4, d: 1.4, walls: &walls)
        addCrate(to: scene, x: -20, z: -18, w: 1.8, h: 1.8, d: 1.6, walls: &walls)
        addCrate(to: scene, x: 4, z: -20, w: 1.5, h: 1.5, d: 1.5, walls: &walls)
        addCrate(to: scene, x: -8, z: 20, w: 1.6, h: 1.2, d: 1.6, walls: &walls)
        addCrate(to: scene, x: -24, z: 18, w: 1.5, h: 1.5, d: 1.5, walls: &walls)
        addCrate(to: scene, x: -23, z: 19.4, w: 1.5, h: 1.5, d: 1.5, walls: &walls)
        addCrate(to: scene, x: -23.5, z: 18.6, w: 1.5, h: 1.5, d: 1.5, y: 1.5, walls: &walls)

        addBarrel(to: scene, x: 12, z: -18, walls: &walls)
        addBarrel(to: scene, x: 13.2, z: -16.8, walls: &walls)
        addBarrel(to: scene, x: -6, z: -10, walls: &walls)

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
        let pad = SCNCylinder(radius: 4.5, height: 0.04)
        pad.firstMaterial = MapTextures.goldSrc(NSColor(calibratedRed: 0.55, green: 0.18, blue: 0.12, alpha: 1))
        let siteNode = SCNNode(geometry: pad)
        siteNode.name = NodeName.site
        siteNode.position = SCNVector3(center.x, 0.02, center.z)
        scene.rootNode.addChildNode(siteNode)

        let c4 = SCNBox(width: 0.42, height: 0.14, length: 0.28, chamferRadius: 0)
        c4.firstMaterial = MapTextures.goldSrc(NSColor(calibratedRed: 0.12, green: 0.14, blue: 0.12, alpha: 1))
        let c4Node = SCNNode(geometry: c4)
        c4Node.position = SCNVector3(center.x, 0.12, center.z)
        scene.rootNode.addChildNode(c4Node)
    }

    private static func addLamps(to scene: SCNScene, at points: [SIMD3<Float>]) {
        for p in points {
            let housing = SCNBox(width: 0.7, height: 0.12, length: 0.7, chamferRadius: 0)
            housing.firstMaterial = MapTextures.goldSrc(MapTextures.metal)
            let lamp = SCNNode(geometry: housing)
            lamp.position = SCNVector3(p.x, p.y, p.z)
            scene.rootNode.addChildNode(lamp)

            let bulb = SCNNode()
            bulb.light = SCNLight()
            bulb.light?.type = .spot
            bulb.light?.spotInnerAngle = 40
            bulb.light?.spotOuterAngle = 78
            bulb.light?.color = NSColor(calibratedRed: 1, green: 0.86, blue: 0.62, alpha: 1)
            bulb.light?.intensity = 650
            bulb.light?.castsShadow = false
            bulb.eulerAngles = SCNVector3(-CGFloat.pi / 2, 0, 0)
            bulb.position = SCNVector3(p.x, p.y - 0.2, p.z)
            scene.rootNode.addChildNode(bulb)
        }
    }

    private static func addLights(to scene: SCNScene) {
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 420
        ambient.light?.color = NSColor(calibratedRed: 0.78, green: 0.74, blue: 0.62, alpha: 1)
        scene.rootNode.addChildNode(ambient)

        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.intensity = 780
        sun.light?.color = NSColor(calibratedRed: 1, green: 0.94, blue: 0.78, alpha: 1)
        sun.light?.castsShadow = true
        sun.light?.shadowSampleCount = 4
        sun.eulerAngles = SCNVector3(-0.95, 0.7, 0)
        scene.rootNode.addChildNode(sun)
    }

    private static func addSky(to scene: SCNScene) {
        let box = SCNBox(width: 160, height: 70, length: 160, chamferRadius: 0)
        let mat = SCNMaterial()
        mat.lightingModel = .constant
        mat.diffuse.contents = NSColor(calibratedRed: 0.52, green: 0.70, blue: 0.88, alpha: 1)
        mat.isDoubleSided = true
        mat.cullMode = .front
        box.firstMaterial = mat
        let node = SCNNode(geometry: box)
        node.position = SCNVector3(0, 20, 0)
        scene.rootNode.addChildNode(node)
    }

    private static func addCrate(
        to scene: SCNScene,
        x: Float,
        z: Float,
        w: Float,
        h: Float,
        d: Float,
        y: Float = 0,
        walls: inout [AABB]
    ) {
        let box = SCNBox(width: CGFloat(w), height: CGFloat(h), length: CGFloat(d), chamferRadius: 0)
        box.firstMaterial = MapTextures.goldSrc(MapTextures.crate)
        let node = SCNNode(geometry: box)
        node.position = SCNVector3(x, y + h / 2, z)
        scene.rootNode.addChildNode(node)
        walls.append(AABB(minX: x - w / 2, maxX: x + w / 2, minZ: z - d / 2, maxZ: z + d / 2))
    }

    private static func addBarrel(to scene: SCNScene, x: Float, z: Float, walls: inout [AABB]) {
        let cyl = SCNCylinder(radius: 0.38, height: 1.1)
        cyl.firstMaterial = MapTextures.goldSrc(MapTextures.hazard)
        let node = SCNNode(geometry: cyl)
        node.position = SCNVector3(x, 0.55, z)
        scene.rootNode.addChildNode(node)
        walls.append(AABB(minX: x - 0.4, maxX: x + 0.4, minZ: z - 0.4, maxZ: z + 0.4))
    }
}
