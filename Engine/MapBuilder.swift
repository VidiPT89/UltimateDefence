import SceneKit
import AppKit
import simd

enum MapBuilder {
    static func make(_ arena: ArenaMap) -> (SCNScene, MapLayout) {
        switch arena {
        case .dust2: return dust2()
        case .aztec: return aztec()
        case .office: return office()
        case .mill: return mill()
        }
    }

    private static func dust2() -> (SCNScene, MapLayout) {
        let kit = MapKit(
            sky: MapTextures.sky(
                top: NSColor(calibratedRed: 0.38, green: 0.60, blue: 0.86, alpha: 1),
                bottom: NSColor(calibratedRed: 0.86, green: 0.80, blue: 0.62, alpha: 1)
            ),
            fog: NSColor(calibratedRed: 0.78, green: 0.76, blue: 0.66, alpha: 1),
            wall: MapTextures.sandstone,
            indoor: false
        )
        let grid = GridMap()
        grid.fill(x0: -3, x1: 5, z0: -24, z1: -18)
        grid.fill(x0: 6, x1: 12, z0: -24, z1: -18)
        grid.fill(x0: -10, x1: -4, z0: -24, z1: -18)
        grid.fill(x0: 0, x1: 2, z0: -17, z1: -10)
        grid.fill(x0: 10, x1: 12, z0: -17, z1: 8)
        grid.fill(x0: -9, x1: -7, z0: -17, z1: -6)
        grid.fill(x0: -4, x1: 8, z0: -9, z1: 2)
        grid.fill(x0: -12, x1: -5, z0: -5, z1: 1)
        grid.fill(x0: -16, x1: -8, z0: 2, z1: 12)
        grid.fill(x0: 1, x1: 3, z0: 3, z1: 8)
        grid.fill(x0: -1, x1: 4, z0: 8, z1: 11)
        grid.fill(x0: 4, x1: 16, z0: 9, z1: 18)
        grid.fill(x0: -2, x1: 3, z0: 12, z1: 18)
        grid.emit(into: kit, walkTexture: MapTextures.sand, ceiling: nil)
        prop(kit, crate: true, 4, -3)
        prop(kit, crate: true, 15, 17)
        prop(kit, crate: false, 8, -20)
        prop(kit, crate: false, -14, 8)
        kit.lamps([c(1, -21, 4.2), c(2, -3, 4.2), c(11, 0, 4.2), c(8, 13, 4.2), c(-12, 6, 4.2)])
        let site = w(9, 13)
        kit.site(at: site)
        return finish(
            kit: kit,
            site: site,
            player: w(0, 15),
            yaw: .pi,
            terrorists: cluster(w(1, -21), count: 6),
            defenders: cluster(w(1, 15), count: 6),
            attackPaths: [
                [w(1, -21), w(1, -12), w(2, -4), w(2, 5), w(6, 12)],
                [w(11, -21), w(11, -10), w(11, 0), w(11, 7), w(12, 12)],
                [w(-8, -21), w(-8, -10), w(-8, -2), w(-2, -2), w(2, 5), w(6, 12)]
            ],
            defendPosts: [
                w(8, 13), w(12, 10), w(2, 7),
                w(1, 10), w(5, 16), w(14, 12)
            ]
        )
    }

    private static func aztec() -> (SCNScene, MapLayout) {
        let kit = MapKit(
            sky: MapTextures.sky(
                top: NSColor(calibratedRed: 0.32, green: 0.56, blue: 0.82, alpha: 1),
                bottom: NSColor(calibratedRed: 0.80, green: 0.78, blue: 0.58, alpha: 1)
            ),
            fog: NSColor(calibratedRed: 0.70, green: 0.74, blue: 0.68, alpha: 1),
            wall: MapTextures.aztecStone,
            indoor: false
        )
        let grid = GridMap()
        grid.fill(x0: -4, x1: 4, z0: -22, z1: -16)
        grid.fill(x0: -10, x1: -5, z0: -22, z1: -16)
        grid.fill(x0: -1, x1: 1, z0: -15, z1: -10)
        grid.fill(x0: -10, x1: -4, z0: -15, z1: -10)
        grid.fill(x0: -6, x1: 6, z0: -9, z1: -6)
        grid.fill(x0: -6, x1: -4, z0: -5, z1: 2)
        grid.fill(x0: 3, x1: 5, z0: -5, z1: 2)
        grid.fill(x0: -6, x1: 6, z0: 3, z1: 6)
        grid.fill(x0: 7, x1: 10, z0: 3, z1: 7)
        grid.fill(x0: -2, x1: 0, z0: 7, z1: 10)
        grid.fill(x0: -12, x1: 2, z0: 11, z1: 18)
        grid.fill(x0: 3, x1: 6, z0: 12, z1: 16)
        grid.fill(x0: 7, x1: 14, z0: 8, z1: 16)
        grid.emit(into: kit, walkTexture: MapTextures.sand, ceiling: nil)
        kit.water(minX: -11, maxX: 13, minZ: -10, maxZ: 5)
        prop(kit, crate: true, -8, -20)
        prop(kit, crate: true, -11, 17)
        kit.lamps([c(0, -19, 4.2), c(-5, -2, 4.2), c(4, -2, 4.2), c(-8, 15, 4.2), c(11, 12, 4.2)])
        let site = w(-8, 15)
        kit.site(at: site)
        return finish(
            kit: kit,
            site: site,
            player: w(11, 13),
            yaw: .pi * 0.85,
            terrorists: cluster(w(0, -19), count: 6),
            defenders: cluster(w(10, 12), count: 6),
            attackPaths: [
                [w(0, -19), w(0, -12), w(-5, -7), w(-5, 0), w(-5, 8), w(-8, 14)],
                [w(0, -19), w(4, -7), w(4, 4), w(8, 6), w(10, 12), w(0, 14), w(-7, 15)]
            ],
            defendPosts: [
                w(-8, 15), w(-1, 12), w(10, 12),
                w(2, 5), w(-10, 16), w(8, 10)
            ]
        )
    }

    private static func office() -> (SCNScene, MapLayout) {
        let kit = MapKit(
            sky: MapTextures.sky(
                top: NSColor(calibratedRed: 0.22, green: 0.26, blue: 0.30, alpha: 1),
                bottom: NSColor(calibratedRed: 0.36, green: 0.38, blue: 0.40, alpha: 1),
                clouds: false
            ),
            fog: NSColor(calibratedRed: 0.28, green: 0.30, blue: 0.32, alpha: 1),
            wall: MapTextures.plaster,
            indoor: true
        )
        let grid = GridMap()
        grid.fill(x0: -3, x1: 4, z0: -20, z1: -14)
        grid.fill(x0: -3, x1: 4, z0: -13, z1: -9)
        grid.fill(x0: 0, x1: 2, z0: -8, z1: 8)
        grid.fill(x0: -8, x1: -1, z0: -4, z1: 2)
        grid.fill(x0: 3, x1: 12, z0: -6, z1: 2)
        grid.fill(x0: -6, x1: -4, z0: 3, z1: 11)
        grid.fill(x0: -2, x1: 3, z0: 9, z1: 11)
        grid.fill(x0: -10, x1: 4, z0: 12, z1: 18)
        grid.fill(x0: 4, x1: 8, z0: 8, z1: 12)
        grid.emit(into: kit, walkTexture: MapTextures.carpet, ceiling: MapTextures.tiles)
        prop(kit, crate: true, 11, -5)
        prop(kit, crate: true, -9, 13)
        kit.lamps([c(0, -17, 4.0), c(1, -2, 4.0), c(8, -2, 4.0), c(-5, 15, 4.0), c(1, 15, 4.0)])
        let site = w(-6, 15)
        kit.site(at: site)
        return finish(
            kit: kit,
            site: site,
            player: w(1, 16),
            yaw: .pi,
            terrorists: cluster(w(0, -17), count: 6),
            defenders: cluster(w(1, 16), count: 6),
            attackPaths: [
                [w(0, -17), w(1, -11), w(1, -2), w(1, 8), w(-4, 14)],
                [w(0, -17), w(1, -2), w(8, -2), w(6, 10), w(1, 14), w(-4, 15)]
            ],
            defendPosts: [
                w(-5, 15), w(1, 10), w(-5, 8),
                w(-8, 16), w(2, 16), w(6, 10)
            ]
        )
    }

    private static func mill() -> (SCNScene, MapLayout) {
        let kit = MapKit(
            sky: MapTextures.sky(
                top: NSColor(calibratedRed: 0.26, green: 0.28, blue: 0.30, alpha: 1),
                bottom: NSColor(calibratedRed: 0.40, green: 0.38, blue: 0.34, alpha: 1),
                clouds: false
            ),
            fog: NSColor(calibratedRed: 0.32, green: 0.32, blue: 0.30, alpha: 1),
            wall: MapTextures.rust,
            indoor: true
        )
        let grid = GridMap()
        grid.fill(x0: -4, x1: 5, z0: -18, z1: -12)
        grid.fill(x0: -1, x1: 2, z0: -11, z1: -7)
        grid.fill(x0: -8, x1: 6, z0: -6, z1: 4)
        grid.fill(x0: -14, x1: -9, z0: -4, z1: 4)
        grid.fill(x0: 7, x1: 14, z0: -3, z1: 6)
        grid.fill(x0: -4, x1: 2, z0: 5, z1: 8)
        grid.fill(x0: 3, x1: 8, z0: 5, z1: 10)
        grid.fill(x0: -12, x1: 4, z0: 9, z1: 16)
        grid.emit(into: kit, walkTexture: MapTextures.concrete, ceiling: MapTextures.metal)
        prop(kit, crate: true, -12, 11)
        prop(kit, crate: false, 13, 5)
        kit.lamps([c(0, -15, 4.0), c(-1, 0, 4.0), c(11, 2, 4.0), c(-6, 13, 4.0), c(1, 13, 4.0)])
        let site = w(-6, 13)
        kit.site(at: site)
        return finish(
            kit: kit,
            site: site,
            player: w(1, 14),
            yaw: .pi,
            terrorists: cluster(w(0, -15), count: 6),
            defenders: cluster(w(1, 14), count: 6),
            attackPaths: [
                [w(0, -15), w(0, -8), w(-1, 0), w(-2, 7), w(-5, 12)],
                [w(0, -15), w(1, -1), w(10, 2), w(6, 8), w(1, 12), w(-5, 13)]
            ],
            defendPosts: [
                w(-5, 13), w(1, 12), w(-10, 12),
                w(-2, 8), w(3, 14), w(11, 3)
            ]
        )
    }

    private static func finish(
        kit: MapKit,
        site: SIMD3<Float>,
        player: SIMD3<Float>,
        yaw: Float,
        terrorists: [SIMD3<Float>],
        defenders: [SIMD3<Float>],
        attackPaths: [[SIMD3<Float>]],
        defendPosts: [SIMD3<Float>]
    ) -> (SCNScene, MapLayout) {
        (kit.scene, kit.layout(
            site: site,
            player: SIMD3(player.x, 1.64, player.z),
            yaw: yaw,
            terrorists: terrorists,
            defenders: defenders,
            attackPaths: attackPaths,
            defendPosts: defendPosts
        ))
    }

    private static func cluster(_ origin: SIMD3<Float>, count: Int) -> [SIMD3<Float>] {
        (0..<count).map { index in
            let offset = (Float(index) - Float(count - 1) / 2) * 1.6
            return SIMD3(origin.x + offset, 0, origin.z)
        }
    }

    private static func w(_ x: Int, _ z: Int) -> SIMD3<Float> {
        GridMap.world(x, z)
    }

    private static func c(_ x: Int, _ z: Int, _ y: Float) -> SIMD3<Float> {
        let p = GridMap.world(x, z)
        return SIMD3(p.x, y, p.z)
    }

    private static func prop(_ kit: MapKit, crate: Bool, _ x: Int, _ z: Int) {
        let p = GridMap.world(x, z)
        if crate {
            kit.crate(x: p.x, z: p.z)
        } else {
            kit.barrel(x: p.x, z: p.z)
        }
    }
}
