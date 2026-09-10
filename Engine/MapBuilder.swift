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
                top: NSColor(calibratedRed: 0.42, green: 0.62, blue: 0.84, alpha: 1),
                bottom: NSColor(calibratedRed: 0.80, green: 0.78, blue: 0.68, alpha: 1)
            ),
            fog: NSColor(calibratedRed: 0.70, green: 0.72, blue: 0.70, alpha: 1),
            wall: MapTextures.sandstone,
            ground: MapTextures.sand,
            groundSize: 96
        )
        let grid = GridMap()
        grid.fill(x0: -4, x1: 3, z0: -19, z1: -14)
        grid.fill(x0: 4, x1: 10, z0: -19, z1: -14)
        grid.fill(x0: -11, x1: -5, z0: -19, z1: -14)
        grid.fill(x0: -1, x1: 0, z0: -13, z1: -8)
        grid.fill(x0: 6, x1: 7, z0: -13, z1: 4)
        grid.fill(x0: -9, x1: -8, z0: -13, z1: -4)
        grid.fill(x0: -6, x1: 5, z0: -7, z1: 1)
        grid.fill(x0: -10, x1: -7, z0: -5, z1: 0)
        grid.fill(x0: -1, x1: 0, z0: 2, z1: 4)
        grid.fill(x0: -3, x1: 11, z0: 5, z1: 13)
        grid.emit(into: kit)
        kit.crate(x: GridMap.world(10, 6).x, z: GridMap.world(10, 6).z)
        kit.crate(x: GridMap.world(9, 6).x, z: GridMap.world(9, 6).z)
        kit.barrel(x: GridMap.world(9, -17).x, z: GridMap.world(9, -17).z)
        kit.lamps([SIMD3(0, 4.2, -32), SIMD3(0, 4.2, -5), SIMD3(15, 4.2, -8), SIMD3(8, 4.2, 18)])
        let site = GridMap.world(4, 10)
        kit.site(at: site)
        return finish(
            kit: kit,
            site: site,
            player: GridMap.world(2, 11),
            yaw: .pi,
            terrorists: cluster(GridMap.world(0, -16), count: 6),
            defenders: cluster(GridMap.world(3, 11), count: 6),
            attackPaths: [
                [GridMap.world(0, -16), GridMap.world(0, -10), GridMap.world(0, -3), GridMap.world(0, 3), GridMap.world(3, 9)],
                [GridMap.world(7, -16), GridMap.world(7, -8), GridMap.world(7, 2), GridMap.world(7, 8)],
                [GridMap.world(-8, -16), GridMap.world(-8, -8), GridMap.world(-8, -2), GridMap.world(-4, -3), GridMap.world(0, -2), GridMap.world(3, 9)]
            ],
            defendPosts: [
                GridMap.world(3, 10), GridMap.world(7, 8), GridMap.world(0, 7),
                GridMap.world(5, 11), GridMap.world(-1, 9), GridMap.world(9, 10)
            ]
        )
    }

    private static func aztec() -> (SCNScene, MapLayout) {
        let kit = MapKit(
            sky: MapTextures.sky(
                top: NSColor(calibratedRed: 0.36, green: 0.58, blue: 0.80, alpha: 1),
                bottom: NSColor(calibratedRed: 0.74, green: 0.80, blue: 0.72, alpha: 1)
            ),
            fog: NSColor(calibratedRed: 0.62, green: 0.70, blue: 0.72, alpha: 1),
            wall: MapTextures.sandstone,
            ground: MapTextures.sand,
            groundSize: 88
        )
        let grid = GridMap()
        grid.fill(x0: -4, x1: 3, z0: -18, z1: -13)
        grid.fill(x0: -1, x1: 0, z0: -12, z1: -7)
        grid.fill(x0: -4, x1: 3, z0: -6, z1: 1)
        grid.fill(x0: -1, x1: 0, z0: 2, z1: 5)
        grid.fill(x0: -10, x1: 3, z0: 6, z1: 13)
        grid.fill(x0: 4, x1: 10, z0: 6, z1: 12)
        grid.emit(into: kit)
        kit.water(minX: -5, maxX: 5, minZ: -8, maxZ: 0)
        kit.crate(x: GridMap.world(-3, -17).x, z: GridMap.world(-3, -17).z)
        kit.crate(x: GridMap.world(10, 11).x, z: GridMap.world(10, 11).z)
        kit.lamps([SIMD3(0, 4.2, -30), SIMD3(0, 4.2, -4), SIMD3(-10, 4.2, 20), SIMD3(14, 4.2, 18)])
        let site = GridMap.world(-6, 10)
        kit.site(at: site)
        return finish(
            kit: kit,
            site: site,
            player: GridMap.world(9, 11),
            yaw: .pi * 0.75,
            terrorists: cluster(GridMap.world(0, -15), count: 6),
            defenders: cluster(GridMap.world(7, 9), count: 6),
            attackPaths: [
                [GridMap.world(0, -15), GridMap.world(0, -9), GridMap.world(0, -2), GridMap.world(0, 4), GridMap.world(-5, 9)],
                [GridMap.world(0, -15), GridMap.world(0, -2), GridMap.world(0, 8), GridMap.world(6, 9)]
            ],
            defendPosts: [
                GridMap.world(-5, 10), GridMap.world(6, 9), GridMap.world(0, 8),
                GridMap.world(-8, 11), GridMap.world(3, 10), GridMap.world(8, 8)
            ]
        )
    }

    private static func office() -> (SCNScene, MapLayout) {
        let kit = MapKit(
            sky: MapTextures.sky(
                top: NSColor(calibratedRed: 0.34, green: 0.40, blue: 0.48, alpha: 1),
                bottom: NSColor(calibratedRed: 0.54, green: 0.56, blue: 0.58, alpha: 1)
            ),
            fog: NSColor(calibratedRed: 0.46, green: 0.48, blue: 0.50, alpha: 1),
            wall: MapTextures.concrete,
            ground: MapTextures.metal,
            groundSize: 80
        )
        let grid = GridMap()
        grid.fill(x0: -4, x1: 3, z0: -16, z1: -11)
        grid.fill(x0: -1, x1: 0, z0: -10, z1: -5)
        grid.fill(x0: -4, x1: 3, z0: -4, z1: 2)
        grid.fill(x0: 4, x1: 8, z0: -2, z1: -1)
        grid.fill(x0: 9, x1: 13, z0: -5, z1: 2)
        grid.fill(x0: -1, x1: 0, z0: 3, z1: 6)
        grid.fill(x0: -9, x1: 3, z0: 7, z1: 13)
        grid.emit(into: kit)
        kit.crate(x: GridMap.world(12, -4).x, z: GridMap.world(12, -4).z)
        kit.crate(x: GridMap.world(-8, 8).x, z: GridMap.world(-8, 8).z)
        kit.lamps([SIMD3(0, 4.0, -26), SIMD3(0, 4.0, -1), SIMD3(22, 4.0, -2), SIMD3(-8, 4.0, 20)])
        let site = GridMap.world(-5, 11)
        kit.site(at: site)
        return finish(
            kit: kit,
            site: site,
            player: GridMap.world(1, 11),
            yaw: .pi,
            terrorists: cluster(GridMap.world(0, -13), count: 6),
            defenders: cluster(GridMap.world(1, 11), count: 6),
            attackPaths: [
                [GridMap.world(0, -13), GridMap.world(0, -7), GridMap.world(0, -1), GridMap.world(0, 5), GridMap.world(-3, 10)],
                [GridMap.world(0, -13), GridMap.world(0, -1), GridMap.world(6, -1), GridMap.world(11, -1)]
            ],
            defendPosts: [
                GridMap.world(-4, 11), GridMap.world(1, 10), GridMap.world(0, 8),
                GridMap.world(-7, 12), GridMap.world(2, 12), GridMap.world(11, 0)
            ]
        )
    }

    private static func mill() -> (SCNScene, MapLayout) {
        let kit = MapKit(
            sky: MapTextures.sky(
                top: NSColor(calibratedRed: 0.38, green: 0.44, blue: 0.50, alpha: 1),
                bottom: NSColor(calibratedRed: 0.58, green: 0.58, blue: 0.56, alpha: 1)
            ),
            fog: NSColor(calibratedRed: 0.50, green: 0.50, blue: 0.50, alpha: 1),
            wall: MapTextures.concrete,
            ground: MapTextures.metal,
            groundSize: 76
        )
        let grid = GridMap()
        grid.fill(x0: -4, x1: 3, z0: -15, z1: -10)
        grid.fill(x0: -1, x1: 0, z0: -9, z1: -4)
        grid.fill(x0: -6, x1: 3, z0: -3, z1: 3)
        grid.fill(x0: 4, x1: 8, z0: -1, z1: 0)
        grid.fill(x0: 9, x1: 13, z0: -3, z1: 5)
        grid.fill(x0: -3, x1: -2, z0: 4, z1: 6)
        grid.fill(x0: -9, x1: 1, z0: 7, z1: 13)
        grid.emit(into: kit)
        kit.crate(x: GridMap.world(-8, 8).x, z: GridMap.world(-8, 8).z)
        kit.barrel(x: GridMap.world(12, 4).x, z: GridMap.world(12, 4).z)
        kit.lamps([SIMD3(0, 4.0, -24), SIMD3(-4, 4.0, 1), SIMD3(22, 4.0, 2), SIMD3(-10, 4.0, 20)])
        let site = GridMap.world(-5, 10)
        kit.site(at: site)
        return finish(
            kit: kit,
            site: site,
            player: GridMap.world(11, 2),
            yaw: .pi * 0.8,
            terrorists: cluster(GridMap.world(0, -12), count: 6),
            defenders: cluster(GridMap.world(11, 1), count: 6),
            attackPaths: [
                [GridMap.world(0, -12), GridMap.world(0, -6), GridMap.world(0, 0), GridMap.world(-2, 5), GridMap.world(-4, 9)],
                [GridMap.world(0, -12), GridMap.world(0, 0), GridMap.world(6, 0), GridMap.world(11, 1)]
            ],
            defendPosts: [
                GridMap.world(-4, 10), GridMap.world(11, 2), GridMap.world(-2, 8),
                GridMap.world(-7, 11), GridMap.world(1, 9), GridMap.world(10, 4)
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
}
