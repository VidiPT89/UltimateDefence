import SceneKit
import AppKit
import simd

enum MapBuilder {
    private static let door: Float = 4

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
        kit.room(minX: -8, maxX: 8, minZ: -38, maxZ: -26, openings: [
            .north(center: 0, width: door),
            .east(center: -32, width: door),
            .west(center: -32, width: door)
        ])
        kit.room(minX: 8, maxX: 22, minZ: -38, maxZ: -26, openings: [
            .west(center: -32, width: door),
            .north(center: 15, width: door)
        ])
        kit.room(minX: -22, maxX: -8, minZ: -38, maxZ: -26, openings: [
            .east(center: -32, width: door),
            .north(center: -16, width: door)
        ])
        kit.hall(minX: -2, maxX: 2, minZ: -26, maxZ: -14)
        kit.hall(minX: 13, maxX: 17, minZ: -26, maxZ: 10)
        kit.hall(minX: -18, maxX: -14, minZ: -26, maxZ: -6)
        kit.room(minX: -12, maxX: 12, minZ: -14, maxZ: 4, openings: [
            .south(center: 0, width: door),
            .north(center: 0, width: door),
            .west(center: -6, width: door)
        ])
        kit.room(minX: -20, maxX: -12, minZ: -10, maxZ: 2, openings: [
            .east(center: -6, width: door),
            .south(center: -16, width: door)
        ])
        kit.hall(minX: -2, maxX: 2, minZ: 4, maxZ: 10)
        kit.room(minX: -6, maxX: 24, minZ: 10, maxZ: 28, openings: [
            .south(center: 0, width: door),
            .south(center: 15, width: door)
        ])
        kit.crate(x: 20, z: 24)
        kit.crate(x: 18.4, z: 24)
        kit.barrel(x: 15, z: -30)
        kit.lamps([SIMD3(0, 4.2, -32), SIMD3(0, 4.2, -5), SIMD3(15, 4.2, -8), SIMD3(8, 4.2, 18)])
        let site = p(8, 20)
        kit.site(at: site)
        return (kit.scene, kit.layout(
            site: site,
            player: SIMD3(4, 1.64, 22),
            yaw: .pi,
            terrorists: Self.cluster(p(0, -32), count: 6, alongX: true),
            defenders: Self.cluster(p(6, 22), count: 6, alongX: true),
            attackPaths: [
                [p(0, -32), p(0, -20), p(0, -5), p(0, 7), p(6, 18)],
                [p(14, -32), p(15, -12), p(15, 12), p(12, 18)],
                [p(-14, -32), p(-16, -16), p(-16, -4), p(-8, -5), p(0, -4), p(6, 18)]
            ],
            defendPosts: [p(6, 20), p(14, 16), p(0, 14), p(10, 22), p(-2, 18), p(16, 20)]
        ))
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
        kit.room(minX: -8, maxX: 8, minZ: -36, maxZ: -24, openings: [.north(center: 0, width: door)])
        kit.hall(minX: -2, maxX: 2, minZ: -24, maxZ: -12)
        kit.room(minX: -8, maxX: 8, minZ: -12, maxZ: 4, openings: [
            .south(center: 0, width: door),
            .north(center: 0, width: door)
        ])
        kit.water(minX: -5, maxX: 5, minZ: -8, maxZ: 0)
        kit.hall(minX: -2, maxX: 2, minZ: 4, maxZ: 12)
        kit.room(minX: -20, maxX: 8, minZ: 12, maxZ: 28, openings: [
            .south(center: 0, width: door),
            .east(center: 20, width: door)
        ])
        kit.room(minX: 8, maxX: 22, minZ: 12, maxZ: 26, openings: [.west(center: 20, width: door)])
        kit.crate(x: -16, z: 24)
        kit.crate(x: 16, z: 20)
        kit.lamps([SIMD3(0, 4.2, -30), SIMD3(0, 4.2, -4), SIMD3(-10, 4.2, 20), SIMD3(14, 4.2, 18)])
        let site = p(-12, 20)
        kit.site(at: site)
        return (kit.scene, kit.layout(
            site: site,
            player: SIMD3(14, 1.64, 18),
            yaw: .pi * 0.75,
            terrorists: Self.cluster(p(0, -30), count: 6, alongX: true),
            defenders: Self.cluster(p(14, 18), count: 6, alongX: true),
            attackPaths: [
                [p(0, -30), p(0, -18), p(0, -4), p(0, 8), p(-8, 18)],
                [p(0, -30), p(0, -4), p(0, 16), p(10, 18)]
            ],
            defendPosts: [p(-10, 20), p(12, 18), p(0, 16), p(-16, 22), p(6, 20), p(16, 16)]
        ))
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
        kit.room(minX: -8, maxX: 8, minZ: -32, maxZ: -20, openings: [.north(center: 0, width: door)])
        kit.hall(minX: -2, maxX: 2, minZ: -20, maxZ: -8)
        kit.room(minX: -8, maxX: 8, minZ: -8, maxZ: 6, openings: [
            .south(center: 0, width: door),
            .north(center: 0, width: door),
            .east(center: -1, width: door)
        ])
        kit.hall(minX: 8, maxX: 18, minZ: -3, maxZ: 1)
        kit.room(minX: 18, maxX: 28, minZ: -10, maxZ: 6, openings: [.west(center: -1, width: door)])
        kit.hall(minX: -2, maxX: 2, minZ: 6, maxZ: 14)
        kit.room(minX: -18, maxX: 8, minZ: 14, maxZ: 28, openings: [.south(center: 0, width: door)])
        kit.crate(x: 22, z: 0)
        kit.crate(x: -12, z: 24)
        kit.lamps([SIMD3(0, 4.0, -26), SIMD3(0, 4.0, -1), SIMD3(22, 4.0, -2), SIMD3(-8, 4.0, 20)])
        let site = p(-10, 22)
        kit.site(at: site)
        return (kit.scene, kit.layout(
            site: site,
            player: SIMD3(2, 1.64, 22),
            yaw: .pi,
            terrorists: Self.cluster(p(0, -26), count: 6, alongX: true),
            defenders: Self.cluster(p(2, 22), count: 6, alongX: true),
            attackPaths: [
                [p(0, -26), p(0, -14), p(0, -1), p(0, 10), p(-6, 20)],
                [p(0, -26), p(0, -1), p(12, -1), p(22, -1)]
            ],
            defendPosts: [p(-8, 22), p(2, 20), p(0, 16), p(-14, 24), p(4, 24), p(20, 2)]
        ))
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
        kit.room(minX: -8, maxX: 8, minZ: -30, maxZ: -18, openings: [.north(center: 0, width: door)])
        kit.hall(minX: -2, maxX: 2, minZ: -18, maxZ: -6)
        kit.room(minX: -12, maxX: 8, minZ: -6, maxZ: 8, openings: [
            .south(center: 0, width: door),
            .north(center: -4, width: door),
            .east(center: 1, width: door)
        ])
        kit.hall(minX: 8, maxX: 18, minZ: -1, maxZ: 3)
        kit.room(minX: 18, maxX: 28, minZ: -6, maxZ: 12, openings: [.west(center: 1, width: door)])
        kit.hall(minX: -6, maxX: -2, minZ: 8, maxZ: 14)
        kit.room(minX: -18, maxX: 4, minZ: 14, maxZ: 28, openings: [.south(center: -4, width: door)])
        kit.crate(x: -12, z: 22)
        kit.barrel(x: 25, z: 8)
        kit.lamps([SIMD3(0, 4.0, -24), SIMD3(-4, 4.0, 1), SIMD3(22, 4.0, 2), SIMD3(-10, 4.0, 20)])
        let site = p(-10, 20)
        kit.site(at: site)
        return (kit.scene, kit.layout(
            site: site,
            player: SIMD3(22, 1.64, 4),
            yaw: .pi * 0.8,
            terrorists: Self.cluster(p(0, -24), count: 6, alongX: true),
            defenders: Self.cluster(p(22, 2), count: 6, alongX: true),
            attackPaths: [
                [p(0, -24), p(0, -12), p(0, 1), p(-4, 11), p(-8, 18)],
                [p(0, -24), p(0, 1), p(12, 1), p(22, 2)]
            ],
            defendPosts: [p(-8, 20), p(22, 4), p(-4, 16), p(-14, 22), p(2, 18), p(20, 8)]
        ))
    }

    private static func p(_ x: Float, _ z: Float) -> SIMD3<Float> {
        SIMD3(x, 0, z)
    }

    private static func cluster(_ origin: SIMD3<Float>, count: Int, alongX: Bool) -> [SIMD3<Float>] {
        (0..<count).map { index in
            let offset = (Float(index) - Float(count - 1) / 2) * 1.6
            if alongX {
                return SIMD3(origin.x + offset, 0, origin.z)
            }
            return SIMD3(origin.x, 0, origin.z + offset)
        }
    }
}
