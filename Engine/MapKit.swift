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

enum WallOpening {
    case north(center: Float, width: Float)
    case south(center: Float, width: Float)
    case east(center: Float, width: Float)
    case west(center: Float, width: Float)
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
    private let thickness: Float = 1.1

    init(sky: NSImage, fog: NSColor, wall: NSImage, ground: NSImage, groundSize: CGFloat) {
        wallTexture = wall
        scene.background.contents = sky
        scene.fogStartDistance = 70
        scene.fogEndDistance = 140
        scene.fogColor = fog
        addLights()
        let box = SCNBox(width: groundSize, height: 0.4, length: groundSize, chamferRadius: 0)
        let tiles = max(10, groundSize / 1.6)
        box.materials = Array(repeating: MapTextures.tiled(ground, repeatU: tiles, repeatV: tiles), count: 6)
        let floor = SCNNode(geometry: box)
        floor.position = SCNVector3(0, -0.2, 0)
        floor.name = NodeName.ground
        scene.rootNode.addChildNode(floor)
    }

    func room(minX: Float, maxX: Float, minZ: Float, maxZ: Float, h: Float = 4.4, openings: [WallOpening] = []) {
        var north: [(Float, Float)] = []
        var south: [(Float, Float)] = []
        var east: [(Float, Float)] = []
        var west: [(Float, Float)] = []
        for opening in openings {
            switch opening {
            case .north(let center, let width): north.append((center, width))
            case .south(let center, let width): south.append((center, width))
            case .east(let center, let width): east.append((center, width))
            case .west(let center, let width): west.append((center, width))
            }
        }
        spanX(z: maxZ, minX: minX, maxX: maxX, gaps: north, h: h)
        spanX(z: minZ, minX: minX, maxX: maxX, gaps: south, h: h)
        spanZ(x: maxX, minZ: minZ, maxZ: maxZ, gaps: east, h: h)
        spanZ(x: minX, minZ: minZ, maxZ: maxZ, gaps: west, h: h)
    }

    func wall(x: Float, z: Float, w: Float, d: Float, h: Float = 4.4, texture: NSImage? = nil) {
        let tex = texture ?? wallTexture
        let box = SCNBox(width: CGFloat(w), height: CGFloat(h), length: CGFloat(d), chamferRadius: 0)
        box.materials = Self.tiledBox(tex, w: w, h: h, d: d)
        let node = SCNNode(geometry: box)
        node.position = SCNVector3(x, h / 2, z)
        scene.rootNode.addChildNode(node)
        walls.append(AABB(minX: x - w / 2, maxX: x + w / 2, minZ: z - d / 2, maxZ: z + d / 2))
    }

    func crate(x: Float, z: Float, w: Float = 1.5, h: Float = 1.5, d: Float = 1.5, y: Float = 0) {
        let box = SCNBox(width: CGFloat(w), height: CGFloat(h), length: CGFloat(d), chamferRadius: 0.04)
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
        let pad = SCNCylinder(radius: 4.2, height: 0.05)
        pad.firstMaterial = MapTextures.goldSrc(NSColor(calibratedRed: 0.52, green: 0.16, blue: 0.1, alpha: 1))
        let siteNode = SCNNode(geometry: pad)
        siteNode.name = NodeName.site
        siteNode.position = SCNVector3(center.x, 0.03, center.z)
        scene.rootNode.addChildNode(siteNode)
        let c4 = SCNBox(width: 0.42, height: 0.14, length: 0.28, chamferRadius: 0.02)
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

    private func spanX(z: Float, minX: Float, maxX: Float, gaps: [(Float, Float)], h: Float) {
        var cursor = minX
        for gap in gaps.sorted(by: { $0.0 < $1.0 }) {
            let g0 = max(minX, gap.0 - gap.1 / 2)
            let g1 = min(maxX, gap.0 + gap.1 / 2)
            if g0 - cursor > 0.9 {
                wall(x: (cursor + g0) / 2, z: z, w: g0 - cursor, d: thickness, h: h)
            }
            cursor = max(cursor, g1)
        }
        if maxX - cursor > 0.9 {
            wall(x: (cursor + maxX) / 2, z: z, w: maxX - cursor, d: thickness, h: h)
        }
    }

    private func spanZ(x: Float, minZ: Float, maxZ: Float, gaps: [(Float, Float)], h: Float) {
        var cursor = minZ
        for gap in gaps.sorted(by: { $0.0 < $1.0 }) {
            let g0 = max(minZ, gap.0 - gap.1 / 2)
            let g1 = min(maxZ, gap.0 + gap.1 / 2)
            if g0 - cursor > 0.9 {
                wall(x: x, z: (cursor + g0) / 2, w: thickness, d: g0 - cursor, h: h)
            }
            cursor = max(cursor, g1)
        }
        if maxZ - cursor > 0.9 {
            wall(x: x, z: (cursor + maxZ) / 2, w: thickness, d: maxZ - cursor, h: h)
        }
    }

    private func addLights() {
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 460
        ambient.light?.color = NSColor(calibratedRed: 0.86, green: 0.82, blue: 0.72, alpha: 1)
        scene.rootNode.addChildNode(ambient)
        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.intensity = 1100
        sun.light?.color = NSColor(calibratedRed: 1, green: 0.96, blue: 0.84, alpha: 1)
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
