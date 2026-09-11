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
    static let solid = "solid"
    static let trim = "trim"
}

struct MapLayout {
    let walls: [AABB]
    let siteCenter: SIMD3<Float>
    let playerSpawn: SIMD3<Float>
    let playerYaw: Float
    let attackerSpawns: [SIMD3<Float>]
    let defenderSpawns: [SIMD3<Float>]
    let attackPaths: [[SIMD3<Float>]]
    let defendPosts: [SIMD3<Float>]
}

final class MapKit {
    let scene = SCNScene()
    var walls: [AABB] = []
    private let wallTexture: NSImage

    init(sky: NSImage, fog: NSColor, wall: NSImage, indoor: Bool) {
        wallTexture = wall
        scene.background.contents = sky
        scene.fogStartDistance = indoor ? 38 : 70
        scene.fogEndDistance = indoor ? 95 : 160
        scene.fogColor = fog
        addLights(indoor: indoor)
        let void = SCNBox(width: 180, height: 1, length: 180, chamferRadius: 0)
        void.firstMaterial = MapTextures.goldSrc(NSColor(calibratedRed: 0.05, green: 0.05, blue: 0.045, alpha: 1))
        let bed = SCNNode(geometry: void)
        bed.position = SCNVector3(0, -0.55, 0)
        bed.name = NodeName.ground
        scene.rootNode.addChildNode(bed)
    }

    func wall(
        x: Float,
        z: Float,
        w: Float,
        d: Float,
        h: Float = 4.0,
        y: Float = 0,
        texture: NSImage? = nil,
        collide: Bool = true
    ) {
        let tex = texture ?? wallTexture
        let box = SCNBox(width: CGFloat(w), height: CGFloat(h), length: CGFloat(d), chamferRadius: 0)
        box.materials = Self.tiledBox(tex, w: w, h: h, d: d)
        let node = SCNNode(geometry: box)
        node.name = collide ? NodeName.solid : NodeName.trim
        node.position = SCNVector3(x, y + h / 2, z)
        scene.rootNode.addChildNode(node)
        if collide {
            walls.append(AABB(minX: x - w / 2, maxX: x + w / 2, minZ: z - d / 2, maxZ: z + d / 2, blocksSight: true))
        }
    }

    func crate(x: Float, z: Float, w: Float = 1.5, h: Float = 1.5, d: Float = 1.5, y: Float = 0) {
        let box = SCNBox(width: CGFloat(w), height: CGFloat(h), length: CGFloat(d), chamferRadius: 0.03)
        box.materials = Self.tiledBox(MapTextures.crate, w: w, h: h, d: d)
        let node = SCNNode(geometry: box)
        node.name = NodeName.solid
        node.position = SCNVector3(x, y + h / 2, z)
        scene.rootNode.addChildNode(node)
        let strap = SCNBox(width: CGFloat(w + 0.04), height: 0.08, length: CGFloat(d + 0.04), chamferRadius: 0)
        strap.firstMaterial = MapTextures.goldSrc(MapTextures.metal)
        for offset in [-h * 0.28, h * 0.28] {
            let band = SCNNode(geometry: strap)
            band.position = SCNVector3(x, y + h / 2 + offset, z)
            scene.rootNode.addChildNode(band)
        }
        walls.append(AABB(minX: x - w / 2, maxX: x + w / 2, minZ: z - d / 2, maxZ: z + d / 2, blocksSight: false))
    }

    func barrel(x: Float, z: Float) {
        let cyl = SCNCylinder(radius: 0.38, height: 1.12)
        cyl.firstMaterial = MapTextures.goldSrc(MapTextures.hazard)
        let node = SCNNode(geometry: cyl)
        node.name = NodeName.solid
        node.position = SCNVector3(x, 0.58, z)
        scene.rootNode.addChildNode(node)
        let ring = SCNTorus(ringRadius: 0.39, pipeRadius: 0.035)
        ring.firstMaterial = MapTextures.goldSrc(MapTextures.metal)
        for y in [0.18, 0.58, 0.98] as [Float] {
            let rim = SCNNode(geometry: ring)
            rim.position = SCNVector3(x, y, z)
            scene.rootNode.addChildNode(rim)
        }
        let lid = SCNCylinder(radius: 0.36, height: 0.05)
        lid.firstMaterial = MapTextures.goldSrc(MapTextures.metal)
        let cap = SCNNode(geometry: lid)
        cap.position = SCNVector3(x, 1.16, z)
        scene.rootNode.addChildNode(cap)
        walls.append(AABB(minX: x - 0.4, maxX: x + 0.4, minZ: z - 0.4, maxZ: z + 0.4, blocksSight: false))
    }

    func slab(x: Float, z: Float, w: Float, d: Float, y: Float, h: Float, texture: NSImage) {
        let box = SCNBox(width: CGFloat(w), height: CGFloat(h), length: CGFloat(d), chamferRadius: 0)
        box.materials = Self.tiledBox(texture, w: w, h: h, d: d)
        let node = SCNNode(geometry: box)
        node.name = NodeName.trim
        node.position = SCNVector3(x, y, z)
        scene.rootNode.addChildNode(node)
    }

    func water(minX: Float, maxX: Float, minZ: Float, maxZ: Float) {
        let w = maxX - minX
        let d = maxZ - minZ
        let plane = SCNBox(width: CGFloat(w), height: 0.08, length: CGFloat(d), chamferRadius: 0)
        plane.firstMaterial = MapTextures.tiled(MapTextures.water, repeatU: CGFloat(w / 3), repeatV: CGFloat(d / 3))
        let node = SCNNode(geometry: plane)
        node.position = SCNVector3((minX + maxX) / 2, 0.02, (minZ + maxZ) / 2)
        scene.rootNode.addChildNode(node)
    }

    func site(at center: SIMD3<Float>) {
        let pad = SCNBox(width: 3.4, height: 0.05, length: 3.4, chamferRadius: 0)
        pad.firstMaterial = MapTextures.tiled(MapTextures.site, repeatU: 1, repeatV: 1)
        let siteNode = SCNNode(geometry: pad)
        siteNode.name = NodeName.site
        siteNode.position = SCNVector3(center.x, 0.08, center.z)
        scene.rootNode.addChildNode(siteNode)
        let c4 = SCNBox(width: 0.42, height: 0.14, length: 0.28, chamferRadius: 0.02)
        c4.firstMaterial = MapTextures.goldSrc(NSColor(calibratedRed: 0.08, green: 0.10, blue: 0.08, alpha: 1))
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
            bulb.light?.color = NSColor(calibratedRed: 1, green: 0.92, blue: 0.74, alpha: 1)
            bulb.light?.intensity = 520
            bulb.light?.attenuationEndDistance = 22
            bulb.position = SCNVector3(p.x, p.y - 0.25, p.z)
            scene.rootNode.addChildNode(bulb)
        }
    }

    func layout(
        site: SIMD3<Float>,
        player: SIMD3<Float>,
        yaw: Float,
        terrorists: [SIMD3<Float>],
        defenders: [SIMD3<Float>],
        attackPaths: [[SIMD3<Float>]],
        defendPosts: [SIMD3<Float>]
    ) -> MapLayout {
        MapLayout(
            walls: walls,
            siteCenter: site,
            playerSpawn: player,
            playerYaw: yaw,
            attackerSpawns: terrorists,
            defenderSpawns: defenders,
            attackPaths: attackPaths,
            defendPosts: defendPosts
        )
    }

    private func addLights(indoor: Bool) {
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = indoor ? 360 : 520
        ambient.light?.color = indoor
            ? NSColor(calibratedRed: 0.62, green: 0.64, blue: 0.60, alpha: 1)
            : NSColor(calibratedRed: 0.78, green: 0.74, blue: 0.64, alpha: 1)
        scene.rootNode.addChildNode(ambient)
        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.intensity = indoor ? 850 : 1200
        sun.light?.color = indoor
            ? NSColor(calibratedRed: 0.92, green: 0.94, blue: 0.90, alpha: 1)
            : NSColor(calibratedRed: 1, green: 0.96, blue: 0.82, alpha: 1)
        sun.light?.castsShadow = false
        sun.eulerAngles = SCNVector3(-0.95, 0.55, 0)
        scene.rootNode.addChildNode(sun)
    }

    private static func tiledBox(_ tex: NSImage, w: Float, h: Float, d: Float) -> [SCNMaterial] {
        let ru = max(1, CGFloat(w / 1.15))
        let rv = max(1, CGFloat(h / 1.15))
        let rt = max(1, CGFloat(d / 1.15))
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
