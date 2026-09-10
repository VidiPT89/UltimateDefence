import SceneKit
import AppKit
import simd

enum MapBuilder {
    static func make(_ arena: ArenaMap) -> (SCNScene, MapLayout) {
        switch arena {
        case .sandlot: return sandlot()
        case .dust2: return dust2()
        case .mill: return mill()
        }
    }

    private static func sandlot() -> (SCNScene, MapLayout) {
        let kit = MapKit(
            sky: NSColor(calibratedRed: 0.58, green: 0.73, blue: 0.88, alpha: 1),
            fog: NSColor(calibratedRed: 0.62, green: 0.74, blue: 0.86, alpha: 1),
            wall: MapTextures.sandstone,
            ground: MapTextures.sand,
            groundSize: 68
        )
        kit.wall(x: 0, z: -33, w: 66, d: 1.4)
        kit.wall(x: 0, z: 33, w: 66, d: 1.4)
        kit.wall(x: -33, z: 0, w: 1.4, d: 66)
        kit.wall(x: 33, z: 0, w: 1.4, d: 66)
        kit.wall(x: -12, z: -8, w: 14, d: 1.6)
        kit.wall(x: 8, z: 6, w: 1.6, d: 18)
        kit.wall(x: -4, z: 14, w: 16, d: 1.6)
        kit.wall(x: 16, z: -14, w: 10, d: 1.6)
        kit.wall(x: -18, z: 4, w: 1.6, d: 12)
        kit.wall(x: 10, z: -4, w: 8, d: 1.4, h: 3.2, texture: MapTextures.concrete)
        kit.crate(x: 18, z: 18)
        kit.crate(x: 19.7, z: 18)
        kit.crate(x: 18.8, z: 18, y: 1.5)
        kit.crate(x: -24, z: 20)
        kit.crate(x: -22.4, z: 21.2)
        kit.crate(x: -23.2, z: 20.5, y: 1.5)
        kit.barrel(x: 12, z: -18)
        kit.barrel(x: 13.2, z: -16.8)
        kit.lamps([SIMD3(0, 5, 0), SIMD3(14, 5, -10), SIMD3(-16, 5, 10), SIMD3(-20, 4.8, 20)])
        let site = SIMD3<Float>(-22, 0, 22)
        kit.site(at: site)
        return (kit.scene, kit.layout(
            site: site,
            player: SIMD3(18, 1.64, -20),
            terrorists: Self.cluster(SIMD3(-22, 0, -22), count: 5, alongX: true),
            defenders: Self.cluster(SIMD3(16, 0, -18), count: 4, alongX: true)
        ))
    }

    private static func dust2() -> (SCNScene, MapLayout) {
        let kit = MapKit(
            sky: NSColor(calibratedRed: 0.62, green: 0.78, blue: 0.92, alpha: 1),
            fog: NSColor(calibratedRed: 0.7, green: 0.78, blue: 0.86, alpha: 1),
            wall: MapTextures.sandstone,
            ground: MapTextures.sand,
            groundSize: 84
        )
        kit.wall(x: 0, z: -40, w: 80, d: 1.6)
        kit.wall(x: 0, z: 40, w: 80, d: 1.6)
        kit.wall(x: -40, z: 0, w: 1.6, d: 80)
        kit.wall(x: 40, z: 0, w: 1.6, d: 80)
        kit.wall(x: 22, z: -8, w: 1.6, d: 36)
        kit.wall(x: 30, z: 10, w: 16, d: 1.6)
        kit.wall(x: -6, z: -6, w: 18, d: 1.6)
        kit.wall(x: -18, z: 8, w: 1.6, d: 22)
        kit.wall(x: 6, z: 18, w: 22, d: 1.6)
        kit.wall(x: -28, z: -16, w: 12, d: 1.6)
        kit.wall(x: 10, z: -22, w: 1.6, d: 14, h: 3.2, texture: MapTextures.concrete)
        kit.crate(x: 26, z: 28, w: 1.7, h: 1.7, d: 1.7)
        kit.crate(x: 28, z: 28, w: 1.7, h: 1.7, d: 1.7)
        kit.crate(x: 27, z: 28, y: 1.7)
        kit.crate(x: 24, z: 24)
        kit.crate(x: -8, z: 22)
        kit.crate(x: 12, z: -28)
        kit.barrel(x: 18, z: -12)
        kit.barrel(x: -12, z: -20)
        kit.lamps([SIMD3(22, 5.2, 22), SIMD3(0, 5.2, 0), SIMD3(-20, 5, -20), SIMD3(24, 5, -18)])
        let site = SIMD3<Float>(26, 0, 30)
        kit.site(at: site)
        return (kit.scene, kit.layout(
            site: site,
            player: SIMD3(8, 1.64, 32),
            terrorists: Self.cluster(SIMD3(-8, 0, -32), count: 5, alongX: true),
            defenders: Self.cluster(SIMD3(12, 0, 30), count: 4, alongX: true)
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
        kit.crate(x: -18, z: 18, w: 1.8, h: 2.2, d: 1.8)
        kit.crate(x: -16, z: 18, w: 1.8, h: 1.4, d: 1.8)
        kit.crate(x: 16, z: -16)
        kit.crate(x: 18, z: 20)
        kit.barrel(x: 4, z: 8)
        kit.barrel(x: 5.2, z: 9)
        kit.lamps([SIMD3(-12, 4.8, 12), SIMD3(12, 4.8, -8), SIMD3(0, 5, 0), SIMD3(-18, 4.6, -16)])
        let site = SIMD3<Float>(-18, 0, 22)
        kit.site(at: site)
        return (kit.scene, kit.layout(
            site: site,
            player: SIMD3(18, 1.64, -22),
            terrorists: Self.cluster(SIMD3(-20, 0, -22), count: 5, alongX: true),
            defenders: Self.cluster(SIMD3(16, 0, -20), count: 4, alongX: true)
        ))
    }

    private static func cluster(_ origin: SIMD3<Float>, count: Int, alongX: Bool) -> [SIMD3<Float>] {
        (0..<count).map { index in
            let offset = (Float(index) - Float(count - 1) / 2) * 2.2
            if alongX {
                return SIMD3(origin.x + offset, 0, origin.z)
            }
            return SIMD3(origin.x, 0, origin.z + offset)
        }
    }
}
