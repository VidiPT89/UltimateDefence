import SceneKit
import AppKit
import simd

enum NodeName {
    static let player = "player"
    static let camera = "fpsCamera"
    static let ground = "ground"
    static let site = "siteA"
    static let terroristPrefix = "bot-t-"
    static let counterPrefix = "bot-ct-"
    static let headSuffix = "-head"
}

struct MapLayout {
    let walls: [AABB]
    let siteCenter: SIMD3<Float>
    let playerSpawn: SIMD3<Float>
    let playerYaw: Float
    let attackerSpawns: [SIMD3<Float>]
    let defenderSpawns: [SIMD3<Float>]
}

final class MapKit {
    let scene = SCNScene()
    var walls: [AABB] = []
    private let wallTexture: NSImage

    init(sky: NSColor, fog: NSColor, wall: NSImage, ground: NSImage, groundSize: CGFloat) {
        wallTexture = wall
        scene.background.contents = sky
        scene.fogStartDistance = 80
        scene.fogEndDistance = 160
        scene.fogColor = fog
        addLights()
        scene.rootNode.addParticleSystem(FX.dustField())
        let box = SCNBox(width: groundSize, height: 0.4, length: groundSize, chamferRadius: 0)
        let tiles = max(8, groundSize / 2)
        box.materials = Array(repeating: MapTextures.tiled(ground, repeatU: tiles, repeatV: tiles), count: 6)
        let floor = SCNNode(geometry: box)
        floor.position = SCNVector3(0, -0.2, 0)
        floor.name = NodeName.ground
        scene.rootNode.addChildNode(floor)
    }

    func wall(x: Float, z: Float, w: Float, d: Float, h: Float = 3.8, texture: NSImage? = nil) {
        let tex = texture ?? wallTexture
        let box = SCNBox(width: CGFloat(w), height: CGFloat(h), length: CGFloat(d), chamferRadius: 0)
        box.materials = Self.tiledBox(tex, w: w, h: h, d: d)
        let node = SCNNode(geometry: box)
        node.position = SCNVector3(x, h / 2, z)
        scene.rootNode.addChildNode(node)
        walls.append(AABB(minX: x - w / 2, maxX: x + w / 2, minZ: z - d / 2, maxZ: z + d / 2))
    }

    func crate(x: Float, z: Float, w: Float = 1.5, h: Float = 1.5, d: Float = 1.5, y: Float = 0) {
        let box = SCNBox(width: CGFloat(w), height: CGFloat(h), length: CGFloat(d), chamferRadius: 0)
        box.materials = Self.tiledBox(MapTextures.crate, w: w, h: h, d: d)
        let node = SCNNode(geometry: box)
        node.position = SCNVector3(x, y + h / 2, z)
        scene.rootNode.addChildNode(node)
        walls.append(AABB(minX: x - w / 2, maxX: x + w / 2, minZ: z - d / 2, maxZ: z + d / 2))
    }

    func barrel(x: Float, z: Float) {
        let cyl = SCNCylinder(radius: 0.38, height: 1.15)
        cyl.firstMaterial = MapTextures.goldSrc(MapTextures.hazard)
        let node = SCNNode(geometry: cyl)
        node.position = SCNVector3(x, 0.58, z)
        scene.rootNode.addChildNode(node)
        walls.append(AABB(minX: x - 0.4, maxX: x + 0.4, minZ: z - 0.4, maxZ: z + 0.4))
    }

    func site(at center: SIMD3<Float>) {
        let pad = SCNCylinder(radius: 4.5, height: 0.05)
        pad.firstMaterial = MapTextures.goldSrc(NSColor(calibratedRed: 0.52, green: 0.16, blue: 0.1, alpha: 1))
        let siteNode = SCNNode(geometry: pad)
        siteNode.name = NodeName.site
        siteNode.position = SCNVector3(center.x, 0.03, center.z)
        scene.rootNode.addChildNode(siteNode)
        let c4 = SCNBox(width: 0.42, height: 0.14, length: 0.28, chamferRadius: 0)
        c4.firstMaterial = MapTextures.goldSrc(NSColor(calibratedRed: 0.1, green: 0.12, blue: 0.1, alpha: 1))
        let c4Node = SCNNode(geometry: c4)
        c4Node.position = SCNVector3(center.x, 0.12, center.z)
        scene.rootNode.addChildNode(c4Node)
    }

    func lamps(_ points: [SIMD3<Float>]) {
        for p in points {
            let housing = SCNBox(width: 0.7, height: 0.12, length: 0.7, chamferRadius: 0)
            housing.firstMaterial = MapTextures.goldSrc(MapTextures.metal)
            let lamp = SCNNode(geometry: housing)
            lamp.position = SCNVector3(p.x, p.y, p.z)
            scene.rootNode.addChildNode(lamp)
            let bulb = SCNNode()
            bulb.light = SCNLight()
            bulb.light?.type = .omni
            bulb.light?.color = NSColor(calibratedRed: 1, green: 0.9, blue: 0.7, alpha: 1)
            bulb.light?.intensity = 380
            bulb.light?.attenuationEndDistance = 18
            bulb.position = SCNVector3(p.x, p.y - 0.25, p.z)
            scene.rootNode.addChildNode(bulb)
        }
    }

    func layout(
        site: SIMD3<Float>,
        player: SIMD3<Float>,
        yaw: Float,
        terrorists: [SIMD3<Float>],
        defenders: [SIMD3<Float>]
    ) -> MapLayout {
        MapLayout(
            walls: walls,
            siteCenter: site,
            playerSpawn: player,
            playerYaw: yaw,
            attackerSpawns: terrorists,
            defenderSpawns: defenders
        )
    }

    private func addLights() {
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 380
        ambient.light?.color = NSColor(calibratedRed: 0.82, green: 0.78, blue: 0.68, alpha: 1)
        scene.rootNode.addChildNode(ambient)
        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.intensity = 920
        sun.light?.color = NSColor(calibratedRed: 1, green: 0.95, blue: 0.82, alpha: 1)
        sun.light?.castsShadow = false
        sun.eulerAngles = SCNVector3(-0.9, 0.65, 0)
        scene.rootNode.addChildNode(sun)
    }

    private static func tiledBox(_ tex: NSImage, w: Float, h: Float, d: Float) -> [SCNMaterial] {
        let ru = max(1, CGFloat(w / 2))
        let rv = max(1, CGFloat(h / 2))
        let rt = max(1, CGFloat(d / 2))
        return [
            MapTextures.tiled(tex, repeatU: ru, repeatV: rv),
            MapTextures.tiled(tex, repeatU: rt, repeatV: rv),
            MapTextures.tiled(tex, repeatU: ru, repeatV: rv),
            MapTextures.tiled(tex, repeatU: rt, repeatV: rv),
            MapTextures.tiled(tex, repeatU: ru, repeatV: rt),
            MapTextures.tiled(tex, repeatU: ru, repeatV: rt)
        ]
    }
}
