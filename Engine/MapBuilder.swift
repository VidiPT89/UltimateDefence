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
            sky: NSColor(calibratedRed: 0.62, green: 0.78, blue: 0.92, alpha: 1),
            fog: NSColor(calibratedRed: 0.7, green: 0.78, blue: 0.86, alpha: 1),
            wall: MapTextures.sandstone,
            ground: MapTextures.sand,
            groundSize: 92
        )
        kit.wall(x: 0, z: -44, w: 88, d: 1.8)
        kit.wall(x: 0, z: 44, w: 88, d: 1.8)
        kit.wall(x: -44, z: 0, w: 1.8, d: 88)
        kit.wall(x: 44, z: 0, w: 1.8, d: 88)

        kit.wall(x: -4, z: -18, w: 22, d: 1.6)
        kit.wall(x: 14, z: -8, w: 1.6, d: 22)
        kit.wall(x: 28, z: -4, w: 1.6, d: 48)
        kit.wall(x: 36, z: 10, w: 14, d: 1.6)
        kit.wall(x: 22, z: 22, w: 18, d: 1.6)
        kit.wall(x: 8, z: 14, w: 1.6, d: 18)
        kit.wall(x: -2, z: 8, w: 16, d: 1.6)
        kit.wall(x: -16, z: 4, w: 1.6, d: 28)
        kit.wall(x: -28, z: 18, w: 18, d: 1.6)
        kit.wall(x: -34, z: 2, w: 1.6, d: 36)
        kit.wall(x: -22, z: -12, w: 16, d: 1.6)
        kit.wall(x: 6, z: 30, w: 1.6, d: 16)
        kit.wall(x: -6, z: 28, w: 18, d: 1.6)
        kit.wall(x: 18, z: -26, w: 1.6, d: 12, h: 3.0, texture: MapTextures.concrete)

        crateStack(kit, x: 24, z: 30)
        crateStack(kit, x: 30, z: 26)
        kit.crate(x: -24, z: 28)
        kit.crate(x: -10, z: 20)
        kit.crate(x: 10, z: -28)
        kit.barrel(x: 20, z: -10)
        kit.barrel(x: -12, z: -16)
        kit.lamps([
            SIMD3(24, 5.2, 28), SIMD3(0, 5.2, 0), SIMD3(-24, 5, 24),
            SIMD3(24, 5, -16), SIMD3(-8, 5, -24), SIMD3(8, 5, 32)
        ])
        let site = SIMD3<Float>(26, 0, 32)
        let player = SIMD3<Float>(6, 1.64, 34)
        kit.site(at: site)
        return (kit.scene, kit.layout(
            site: site,
            player: player,
            yaw: Self.facing(from: player, to: site),
            terrorists: Self.cluster(SIMD3(-2, 0, -34), count: 6, alongX: true),
            defenders: Self.cluster(SIMD3(10, 0, 32), count: 6, alongX: true)
        ))
    }

    private static func aztec() -> (SCNScene, MapLayout) {
        let kit = MapKit(
            sky: NSColor(calibratedRed: 0.55, green: 0.72, blue: 0.9, alpha: 1),
            fog: NSColor(calibratedRed: 0.6, green: 0.72, blue: 0.82, alpha: 1),
            wall: MapTextures.sandstone,
            ground: MapTextures.sand,
            groundSize: 80
        )
        kit.wall(x: 0, z: -38, w: 76, d: 1.6)
        kit.wall(x: 0, z: 38, w: 76, d: 1.6)
        kit.wall(x: -38, z: 0, w: 1.6, d: 76)
        kit.wall(x: 38, z: 0, w: 1.6, d: 76)
        kit.wall(x: -10, z: -6, w: 28, d: 1.8, h: 5)
        kit.wall(x: 12, z: 8, w: 1.8, d: 26, h: 5)
        kit.wall(x: -18, z: 14, w: 1.8, d: 20, h: 4.4)
        kit.wall(x: 18, z: -16, w: 22, d: 1.8, h: 4.4)
        kit.wall(x: 0, z: 22, w: 18, d: 1.6)
        crateStack(kit, x: 20, z: 22)
        kit.crate(x: -22, z: 20, w: 1.8, h: 2.2, d: 1.8)
        kit.barrel(x: 8, z: -8)
        kit.lamps([SIMD3(-14, 5.4, 12), SIMD3(16, 5.4, -10), SIMD3(0, 5.6, 0), SIMD3(18, 5, 20)])
        let site = SIMD3<Float>(-20, 0, 24)
        let player = SIMD3<Float>(20, 1.64, -22)
        kit.site(at: site)
        return (kit.scene, kit.layout(
            site: site,
            player: player,
            yaw: Self.facing(from: player, to: site),
            terrorists: Self.cluster(SIMD3(-16, 0, -28), count: 6, alongX: true),
            defenders: Self.cluster(SIMD3(16, 0, -18), count: 6, alongX: true)
        ))
    }

    private static func office() -> (SCNScene, MapLayout) {
        let kit = MapKit(
            sky: NSColor(calibratedRed: 0.42, green: 0.5, blue: 0.58, alpha: 1),
            fog: NSColor(calibratedRed: 0.48, green: 0.52, blue: 0.56, alpha: 1),
            wall: MapTextures.concrete,
            ground: MapTextures.metal,
            groundSize: 72
        )
        kit.wall(x: 0, z: -34, w: 68, d: 1.4)
        kit.wall(x: 0, z: 34, w: 68, d: 1.4)
        kit.wall(x: -34, z: 0, w: 1.4, d: 68)
        kit.wall(x: 34, z: 0, w: 1.4, d: 68)
        kit.wall(x: -8, z: -8, w: 1.5, d: 24)
        kit.wall(x: 8, z: 6, w: 1.5, d: 22)
        kit.wall(x: 0, z: 16, w: 20, d: 1.5)
        kit.wall(x: 18, z: -4, w: 1.5, d: 18)
        kit.wall(x: -18, z: 8, w: 14, d: 1.5)
        kit.crate(x: 20, z: 20, w: 1.4, h: 1.2, d: 2.4)
        kit.crate(x: -20, z: 18)
        kit.barrel(x: 4, z: -16)
        kit.lamps([SIMD3(-10, 4.6, 10), SIMD3(10, 4.6, -6), SIMD3(0, 4.8, 0), SIMD3(18, 4.6, 16)])
        let site = SIMD3<Float>(-20, 0, 22)
        let player = SIMD3<Float>(22, 1.64, -22)
        kit.site(at: site)
        return (kit.scene, kit.layout(
            site: site,
            player: player,
            yaw: Self.facing(from: player, to: site),
            terrorists: Self.cluster(SIMD3(-18, 0, -24), count: 6, alongX: true),
            defenders: Self.cluster(SIMD3(18, 0, -18), count: 6, alongX: true)
        ))
    }

    private static func mill() -> (SCNScene, MapLayout) {
        let kit = MapKit(
            sky: NSColor(calibratedRed: 0.45, green: 0.52, blue: 0.58, alpha: 1),
            fog: NSColor(calibratedRed: 0.5, green: 0.54, blue: 0.56, alpha: 1),
            wall: MapTextures.concrete,
            ground: MapTextures.metal,
            groundSize: 64
        )
        kit.wall(x: 0, z: -30, w: 60, d: 1.4)
        kit.wall(x: 0, z: 30, w: 60, d: 1.4)
        kit.wall(x: -30, z: 0, w: 1.4, d: 60)
        kit.wall(x: 30, z: 0, w: 1.4, d: 60)
        kit.wall(x: -10, z: 0, w: 1.5, d: 28, texture: MapTextures.sandstone)
        kit.wall(x: 10, z: 6, w: 1.5, d: 22, texture: MapTextures.sandstone)
        kit.wall(x: 0, z: -10, w: 20, d: 1.5, texture: MapTextures.sandstone)
        kit.wall(x: 0, z: 16, w: 14, d: 1.5, texture: MapTextures.sandstone)
        crateStack(kit, x: -18, z: 18)
        kit.crate(x: 16, z: -16)
        kit.barrel(x: 4, z: 8)
        kit.lamps([SIMD3(-12, 4.8, 12), SIMD3(12, 4.8, -8), SIMD3(0, 5, 0), SIMD3(-18, 4.6, -16)])
        let site = SIMD3<Float>(-18, 0, 22)
        let player = SIMD3<Float>(18, 1.64, -22)
        kit.site(at: site)
        return (kit.scene, kit.layout(
            site: site,
            player: player,
            yaw: Self.facing(from: player, to: site),
            terrorists: Self.cluster(SIMD3(-20, 0, -22), count: 6, alongX: true),
            defenders: Self.cluster(SIMD3(16, 0, -20), count: 6, alongX: true)
        ))
    }

    private static func crateStack(_ kit: MapKit, x: Float, z: Float) {
        kit.crate(x: x, z: z, w: 1.7, h: 1.7, d: 1.7)
        kit.crate(x: x + 1.8, z: z, w: 1.7, h: 1.7, d: 1.7)
        kit.crate(x: x + 0.9, z: z, y: 1.7)
    }

    private static func facing(from: SIMD3<Float>, to: SIMD3<Float>) -> Float {
        atan2(-(to.x - from.x), -(to.z - from.z))
    }

    private static func cluster(_ origin: SIMD3<Float>, count: Int, alongX: Bool) -> [SIMD3<Float>] {
        (0..<count).map { index in
            let offset = (Float(index) - Float(count - 1) / 2) * 2.0
            if alongX {
                return SIMD3(origin.x + offset, 0, origin.z)
            }
            return SIMD3(origin.x, 0, origin.z + offset)
        }
    }
}
