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

enum WallOpening {
    case north(center: Float, width: Float)
    case south(center: Float, width: Float)
    case east(center: Float, width: Float)
    case west(center: Float, width: Float)
}

struct MapLayout {
    let walls: [AABB]
    let floors: [Platform]
    let siteCenter: SIMD3<Float>
    let playerSpawn: SIMD3<Float>
    let playerYaw: Float
    let attackerSpawns: [SIMD3<Float>]
    let defenderSpawns: [SIMD3<Float>]
}

final class MapKit {
    let scene = SCNScene()
    var walls: [AABB] = []
    var floors: [Platform] = []
    private let wallTexture: NSImage
    private let thickness: Float = 1.1
    private let doorHeight: Float = 2.52

    init(sky: NSImage, fog: NSColor, wall: NSImage, ground: NSImage, groundSize: CGFloat) {
        wallTexture = wall
        scene.background.contents = sky
        scene.fogStartDistance = 42
        scene.fogEndDistance = 110
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
        slab(minX: minX, maxX: maxX, minZ: minZ, maxZ: maxZ, y: 0.02, h: 0.05, texture: MapTextures.concrete, name: NodeName.trim)
        slab(minX: minX, maxX: maxX, minZ: minZ, maxZ: maxZ, y: h - 0.12, h: 0.22, texture: MapTextures.concrete, name: NodeName.solid)
        for opening in openings {
            doorway(opening, minX: minX, maxX: maxX, minZ: minZ, maxZ: maxZ, h: h)
        }
    }

    func wall(
        x: Float,
        z: Float,
        w: Float,
        d: Float,
        h: Float = 4.4,
        y: Float = 0,
        texture: NSImage? = nil,
        collide: Bool = true
    ) {
        let tex = texture ?? wallTexture
        let box = SCNBox(width: CGFloat(w), height: CGFloat(h), length: CGFloat(d), chamferRadius: 0.02)
        box.materials = Self.tiledBox(tex, w: w, h: h, d: d)
        let node = SCNNode(geometry: box)
        node.name = collide ? NodeName.solid : NodeName.trim
        node.position = SCNVector3(x, y + h / 2, z)
        scene.rootNode.addChildNode(node)
        if y < 0.05, collide {
            let cap = SCNBox(width: CGFloat(w + 0.08), height: 0.14, length: CGFloat(d + 0.08), chamferRadius: 0)
            cap.materials = Self.tiledBox(MapTextures.concrete, w: w, h: 0.14, d: d)
            let lid = SCNNode(geometry: cap)
            lid.name = NodeName.trim
            lid.position = SCNVector3(x, y + h + 0.05, z)
            scene.rootNode.addChildNode(lid)
        }
        if collide {
            walls.append(AABB(minX: x - w / 2, maxX: x + w / 2, minZ: z - d / 2, maxZ: z + d / 2, blocksSight: true))
        }
    }

    func compound(minX: Float, maxX: Float, minZ: Float, maxZ: Float, h: Float = 5.2) {
        let t = thickness
        wall(x: (minX + maxX) / 2, z: minZ, w: maxX - minX + t, d: t, h: h)
        wall(x: (minX + maxX) / 2, z: maxZ, w: maxX - minX + t, d: t, h: h)
        wall(x: minX, z: (minZ + maxZ) / 2, w: t, d: maxZ - minZ, h: h)
        wall(x: maxX, z: (minZ + maxZ) / 2, w: t, d: maxZ - minZ, h: h)
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

    func pillar(x: Float, z: Float, h: Float = 4.2) {
        wall(x: x, z: z, w: 0.72, d: 0.72, h: h, texture: MapTextures.concrete)
        wall(x: x, z: z, w: 0.92, d: 0.92, h: 0.22, y: 0, texture: MapTextures.concrete, collide: false)
        wall(x: x, z: z, w: 0.88, d: 0.88, h: 0.18, y: h - 0.18, texture: MapTextures.concrete, collide: false)
    }

    func pipe(from: SIMD3<Float>, to: SIMD3<Float>) {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let dz = to.z - from.z
        let length = hypot(hypot(dx, dy), dz)
        guard length > 0.3 else { return }
        let cyl = SCNCylinder(radius: 0.09, height: CGFloat(length))
        cyl.firstMaterial = MapTextures.goldSrc(MapTextures.metal)
        let node = SCNNode(geometry: cyl)
        node.position = SCNVector3((from.x + to.x) / 2, (from.y + to.y) / 2, (from.z + to.z) / 2)
        node.look(at: SCNVector3(to.x, to.y, to.z))
        node.eulerAngles.x += .pi / 2
        scene.rootNode.addChildNode(node)
    }

    func hall(minX: Float, maxX: Float, minZ: Float, maxZ: Float, h: Float = 3.7) {
        let alongZ = (maxZ - minZ) >= (maxX - minX)
        if alongZ {
            wall(x: minX, z: (minZ + maxZ) / 2, w: thickness, d: maxZ - minZ, h: h)
            wall(x: maxX, z: (minZ + maxZ) / 2, w: thickness, d: maxZ - minZ, h: h)
        } else {
            wall(x: (minX + maxX) / 2, z: minZ, w: maxX - minX, d: thickness, h: h)
            wall(x: (minX + maxX) / 2, z: maxZ, w: maxX - minX, d: thickness, h: h)
        }
        slab(minX: minX, maxX: maxX, minZ: minZ, maxZ: maxZ, y: 0.02, h: 0.05, texture: MapTextures.concrete, name: NodeName.trim)
        slab(minX: minX, maxX: maxX, minZ: minZ, maxZ: maxZ, y: h - 0.12, h: 0.2, texture: MapTextures.concrete, name: NodeName.solid)
    }

    func platform(minX: Float, maxX: Float, minZ: Float, maxZ: Float, height: Float) {
        guard height > 0.08 else { return }
        let w = maxX - minX
        let d = maxZ - minZ
        let box = SCNBox(width: CGFloat(w), height: CGFloat(height), length: CGFloat(d), chamferRadius: 0.02)
        box.materials = Self.tiledBox(MapTextures.concrete, w: w, h: height, d: d)
        let node = SCNNode(geometry: box)
        node.name = NodeName.trim
        node.position = SCNVector3((minX + maxX) / 2, height / 2, (minZ + maxZ) / 2)
        scene.rootNode.addChildNode(node)
        floors.append(Platform(minX: minX, maxX: maxX, minZ: minZ, maxZ: maxZ, height: height))
    }

    func steps(x: Float, z: Float, dx: Float, dz: Float, count: Int, width: Float, rise: Float, run: Float) {
        for index in 0..<count {
            let t = Float(index)
            let cx = x + dx * t * run
            let cz = z + dz * t * run
            let h = rise * Float(index + 1)
            let hx = abs(dx) > 0.5 ? run * 0.55 : width / 2
            let hz = abs(dz) > 0.5 ? run * 0.55 : width / 2
            platform(minX: cx - hx, maxX: cx + hx, minZ: cz - hz, maxZ: cz + hz, height: h)
        }
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
            bulb.light?.intensity = 340
            bulb.light?.attenuationEndDistance = 18
            bulb.position = SCNVector3(p.x, p.y - 0.25, p.z)
            scene.rootNode.addChildNode(bulb)
        }
    }

    private func slab(minX: Float, maxX: Float, minZ: Float, maxZ: Float, y: Float, h: Float, texture: NSImage, name: String) {
        let w = maxX - minX
        let d = maxZ - minZ
        guard w > 1, d > 1 else { return }
        let box = SCNBox(width: CGFloat(w), height: CGFloat(h), length: CGFloat(d), chamferRadius: 0)
        box.materials = Self.tiledBox(texture, w: w, h: h, d: d)
        let node = SCNNode(geometry: box)
        node.name = name
        node.position = SCNVector3((minX + maxX) / 2, y + h / 2, (minZ + maxZ) / 2)
        scene.rootNode.addChildNode(node)
    }

    private func doorway(_ opening: WallOpening, minX: Float, maxX: Float, minZ: Float, maxZ: Float, h: Float) {
        let lintel = max(0.6, h - doorHeight)
        switch opening {
        case .north(let center, let width):
            wall(x: center, z: maxZ, w: width, d: thickness, h: lintel, y: doorHeight, collide: false)
            frameX(center: center, z: maxZ, width: width)
        case .south(let center, let width):
            wall(x: center, z: minZ, w: width, d: thickness, h: lintel, y: doorHeight, collide: false)
            frameX(center: center, z: minZ, width: width)
        case .east(let center, let width):
            wall(x: maxX, z: center, w: thickness, d: width, h: lintel, y: doorHeight, collide: false)
            frameZ(center: center, x: maxX, width: width)
        case .west(let center, let width):
            wall(x: minX, z: center, w: thickness, d: width, h: lintel, y: doorHeight, collide: false)
            frameZ(center: center, x: minX, width: width)
        }
    }

    private func frameX(center: Float, z: Float, width: Float) {
        let wood = MapTextures.wood
        wall(x: center - width / 2, z: z, w: 0.18, d: thickness + 0.16, h: doorHeight, y: 0, texture: wood, collide: false)
        wall(x: center + width / 2, z: z, w: 0.18, d: thickness + 0.16, h: doorHeight, y: 0, texture: wood, collide: false)
        wall(x: center, z: z, w: width + 0.2, d: thickness + 0.16, h: 0.16, y: doorHeight - 0.08, texture: wood, collide: false)
    }

    private func frameZ(center: Float, x: Float, width: Float) {
        let wood = MapTextures.wood
        wall(x: x, z: center - width / 2, w: thickness + 0.16, d: 0.18, h: doorHeight, y: 0, texture: wood, collide: false)
        wall(x: x, z: center + width / 2, w: thickness + 0.16, d: 0.18, h: doorHeight, y: 0, texture: wood, collide: false)
        wall(x: x, z: center, w: thickness + 0.16, d: width + 0.2, h: 0.16, y: doorHeight - 0.08, texture: wood, collide: false)
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
            floors: floors,
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
        ambient.light?.intensity = 380
        ambient.light?.color = NSColor(calibratedRed: 0.72, green: 0.70, blue: 0.64, alpha: 1)
        scene.rootNode.addChildNode(ambient)
        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.intensity = 1100
        sun.light?.color = NSColor(calibratedRed: 1, green: 0.97, blue: 0.90, alpha: 1)
        sun.light?.castsShadow = false
        sun.eulerAngles = SCNVector3(-0.9, 0.65, 0)
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
