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
                top: NSColor(calibratedRed: 0.45, green: 0.68, blue: 0.92, alpha: 1),
                bottom: NSColor(calibratedRed: 0.78, green: 0.86, blue: 0.94, alpha: 1)
            ),
            fog: NSColor(calibratedRed: 0.72, green: 0.78, blue: 0.84, alpha: 1),
            wall: MapTextures.sandstone,
            ground: MapTextures.sand,
            groundSize: 96
        )
        kit.room(minX: -12, maxX: 12, minZ: -44, maxZ: -28, openings: [
            .north(center: 0, width: 8),
            .east(center: -36, width: 7)
        ])
        kit.room(minX: 12, maxX: 36, minZ: -44, maxZ: -20, openings: [
            .west(center: -36, width: 7),
            .north(center: 28, width: 8)
        ])
        kit.room(minX: 20, maxX: 36, minZ: -20, maxZ: 20, openings: [
            .south(center: 28, width: 8),
            .north(center: 28, width: 8)
        ])
        kit.room(minX: 16, maxX: 38, minZ: 20, maxZ: 40, openings: [
            .south(center: 28, width: 8),
            .south(center: 16, width: 6),
            .west(center: 30, width: 7)
        ])
        kit.room(minX: -12, maxX: 14, minZ: -28, maxZ: 12, openings: [
            .south(center: 0, width: 8),
            .north(center: 4, width: 8),
            .east(center: 8, width: 6),
            .west(center: 2, width: 7)
        ])
        kit.room(minX: 10, maxX: 22, minZ: 6, maxZ: 22, openings: [
            .west(center: 8, width: 6),
            .north(center: 16, width: 6)
        ])
        kit.room(minX: -8, maxX: 16, minZ: 12, maxZ: 40, openings: [
            .south(center: 4, width: 8),
            .east(center: 30, width: 7)
        ])
        kit.room(minX: -40, maxX: -12, minZ: 18, maxZ: 40, openings: [
            .south(center: -26, width: 8),
            .east(center: 30, width: 6)
        ])
        kit.room(minX: -40, maxX: -12, minZ: -16, maxZ: 18, openings: [
            .north(center: -26, width: 8),
            .east(center: 2, width: 7)
        ])
        kit.compound(minX: -42, maxX: 40, minZ: -46, maxZ: 42)
        kit.crate(x: 34, z: 36)
        kit.crate(x: 32.2, z: 36)
        kit.crate(x: 33.1, z: 36, y: 1.5)
        kit.crate(x: 22, z: 36)
        kit.crate(x: 0, z: -8)
        kit.crate(x: 2, z: -8)
        kit.crate(x: -26, z: 8)
        kit.barrel(x: 24, z: -24)
        kit.barrel(x: -22, z: 8)
        kit.barrel(x: 18, z: 8)
        kit.pillar(x: 8, z: -8)
        kit.pillar(x: -8, z: 4)
        kit.pillar(x: 22, z: 8)
        kit.pipe(from: SIMD3(0, 4.1, -36), to: SIMD3(0, 4.1, 8))
        kit.pipe(from: SIMD3(28, 4.1, -30), to: SIMD3(28, 4.1, 36))
        kit.lamps([
            SIMD3(28, 5.2, 30), SIMD3(4, 5.2, 24), SIMD3(0, 5.2, -8),
            SIMD3(28, 5, -30), SIMD3(-26, 5, 30), SIMD3(-26, 5, 0)
        ])
        let site = SIMD3<Float>(28, 0, 30)
        let player = SIMD3<Float>(4, 1.64, 32)
        kit.site(at: site)
        return (kit.scene, kit.layout(
            site: site,
            player: player,
            yaw: 0,
            terrorists: Self.cluster(SIMD3(0, 0, -36), count: 6, alongX: true),
            defenders: Self.cluster(SIMD3(6, 0, 28), count: 6, alongX: true)
        ))
    }

    private static func aztec() -> (SCNScene, MapLayout) {
        let kit = MapKit(
            sky: MapTextures.sky(
                top: NSColor(calibratedRed: 0.40, green: 0.66, blue: 0.90, alpha: 1),
                bottom: NSColor(calibratedRed: 0.74, green: 0.84, blue: 0.92, alpha: 1)
            ),
            fog: NSColor(calibratedRed: 0.62, green: 0.74, blue: 0.82, alpha: 1),
            wall: MapTextures.sandstone,
            ground: MapTextures.sand,
            groundSize: 88
        )
        kit.room(minX: -16, maxX: 16, minZ: -38, maxZ: -18, openings: [.north(center: 0, width: 10)])
        kit.room(minX: -10, maxX: 10, minZ: -18, maxZ: 6, openings: [
            .south(center: 0, width: 10),
            .north(center: 0, width: 10)
        ])
        kit.water(minX: -8, maxX: 8, minZ: -10, maxZ: 2)
        kit.room(minX: -28, maxX: 8, minZ: 6, maxZ: 36, openings: [
            .south(center: 0, width: 10),
            .east(center: 20, width: 8)
        ])
        kit.room(minX: 8, maxX: 30, minZ: 4, maxZ: 28, openings: [.west(center: 20, width: 8)])
        kit.compound(minX: -30, maxX: 32, minZ: -40, maxZ: 38)
        kit.crate(x: -22, z: 30)
        kit.crate(x: -20, z: 30)
        kit.crate(x: 24, z: 22)
        kit.crate(x: 22, z: 20)
        kit.barrel(x: 4, z: -20)
        kit.pillar(x: -6, z: 8)
        kit.pillar(x: 6, z: 16)
        kit.pipe(from: SIMD3(0, 4.2, -30), to: SIMD3(0, 4.2, 20))
        kit.lamps([SIMD3(0, 5.4, -28), SIMD3(0, 5.4, -6), SIMD3(-16, 5.4, 22), SIMD3(18, 5.2, 16)])
        let site = SIMD3<Float>(-16, 0, 26)
        let player = SIMD3<Float>(18, 1.64, 16)
        kit.site(at: site)
        return (kit.scene, kit.layout(
            site: site,
            player: player,
            yaw: .pi * 0.65,
            terrorists: Self.cluster(SIMD3(0, 0, -30), count: 6, alongX: true),
            defenders: Self.cluster(SIMD3(16, 0, 12), count: 6, alongX: true)
        ))
    }

    private static func office() -> (SCNScene, MapLayout) {
        let kit = MapKit(
            sky: MapTextures.sky(
                top: NSColor(calibratedRed: 0.38, green: 0.46, blue: 0.56, alpha: 1),
                bottom: NSColor(calibratedRed: 0.58, green: 0.62, blue: 0.66, alpha: 1)
            ),
            fog: NSColor(calibratedRed: 0.5, green: 0.54, blue: 0.56, alpha: 1),
            wall: MapTextures.concrete,
            ground: MapTextures.metal,
            groundSize: 78
        )
        kit.room(minX: -14, maxX: 14, minZ: -34, maxZ: -16, openings: [.north(center: 0, width: 7)])
        kit.room(minX: -8, maxX: 8, minZ: -16, maxZ: 8, openings: [
            .south(center: 0, width: 7),
            .north(center: 0, width: 7),
            .east(center: -4, width: 6)
        ])
        kit.room(minX: 8, maxX: 28, minZ: -18, maxZ: 6, openings: [.west(center: -4, width: 6)])
        kit.room(minX: -24, maxX: 10, minZ: 8, maxZ: 32, openings: [.south(center: 0, width: 7)])
        kit.compound(minX: -26, maxX: 30, minZ: -36, maxZ: 34)
        kit.crate(x: 22, z: -8, w: 1.6, h: 1.1, d: 2.2)
        kit.crate(x: 20, z: -8, w: 1.4, h: 1.1, d: 1.6)
        kit.crate(x: -18, z: 26)
        kit.crate(x: 0, z: -4)
        kit.barrel(x: 24, z: 0)
        kit.pillar(x: -6, z: 8)
        kit.pillar(x: 16, z: -8)
        kit.pipe(from: SIMD3(-10, 3.9, -20), to: SIMD3(-10, 3.9, 24))
        kit.lamps([SIMD3(0, 4.6, -24), SIMD3(0, 4.6, -4), SIMD3(18, 4.6, -6), SIMD3(-10, 4.6, 20)])
        let site = SIMD3<Float>(-14, 0, 22)
        let player = SIMD3<Float>(4, 1.64, 24)
        kit.site(at: site)
        return (kit.scene, kit.layout(
            site: site,
            player: player,
            yaw: .pi,
            terrorists: Self.cluster(SIMD3(0, 0, -26), count: 6, alongX: true),
            defenders: Self.cluster(SIMD3(2, 0, 20), count: 6, alongX: true)
        ))
    }

    private static func mill() -> (SCNScene, MapLayout) {
        let kit = MapKit(
            sky: MapTextures.sky(
                top: NSColor(calibratedRed: 0.42, green: 0.50, blue: 0.58, alpha: 1),
                bottom: NSColor(calibratedRed: 0.62, green: 0.64, blue: 0.66, alpha: 1)
            ),
            fog: NSColor(calibratedRed: 0.52, green: 0.54, blue: 0.56, alpha: 1),
            wall: MapTextures.concrete,
            ground: MapTextures.metal,
            groundSize: 70
        )
        kit.room(minX: -14, maxX: 14, minZ: -30, maxZ: -10, openings: [.north(center: 0, width: 8)])
        kit.room(minX: -18, maxX: 8, minZ: -10, maxZ: 12, openings: [
            .south(center: 0, width: 8),
            .north(center: -6, width: 8),
            .east(center: 2, width: 7)
        ])
        kit.room(minX: 8, maxX: 26, minZ: -8, maxZ: 16, openings: [.west(center: 2, width: 7)])
        kit.room(minX: -24, maxX: 4, minZ: 12, maxZ: 30, openings: [.south(center: -6, width: 8)])
        kit.compound(minX: -26, maxX: 28, minZ: -32, maxZ: 32)
        kit.crate(x: -18, z: 24)
        kit.crate(x: -16, z: 24)
        kit.crate(x: 4, z: 0)
        kit.barrel(x: 18, z: 8)
        kit.barrel(x: -8, z: -16)
        kit.pillar(x: -4, z: 2)
        kit.pillar(x: 12, z: 6)
        kit.pipe(from: SIMD3(-6, 3.9, -18), to: SIMD3(-6, 3.9, 22))
        kit.lamps([SIMD3(0, 4.8, -20), SIMD3(-6, 4.8, 0), SIMD3(16, 4.8, 4), SIMD3(-12, 4.8, 20)])
        let site = SIMD3<Float>(-14, 0, 22)
        let player = SIMD3<Float>(16, 1.64, 6)
        kit.site(at: site)
        return (kit.scene, kit.layout(
            site: site,
            player: player,
            yaw: .pi * 0.7,
            terrorists: Self.cluster(SIMD3(0, 0, -22), count: 6, alongX: true),
            defenders: Self.cluster(SIMD3(14, 0, 4), count: 6, alongX: true)
        ))
    }

    private static func cluster(_ origin: SIMD3<Float>, count: Int, alongX: Bool) -> [SIMD3<Float>] {
        (0..<count).map { index in
            let offset = (Float(index) - Float(count - 1) / 2) * 1.8
            if alongX {
                return SIMD3(origin.x + offset, 0, origin.z)
            }
            return SIMD3(origin.x, 0, origin.z + offset)
        }
    }
}
