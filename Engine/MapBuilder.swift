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
                top: NSColor(calibratedRed: 0.38, green: 0.58, blue: 0.82, alpha: 1),
                bottom: NSColor(calibratedRed: 0.78, green: 0.74, blue: 0.62, alpha: 1)
            ),
            fog: NSColor(calibratedRed: 0.68, green: 0.66, blue: 0.58, alpha: 1),
            wall: MapTextures.sandstone,
            ground: MapTextures.sand,
            groundSize: 108
        )
        kit.room(minX: -9, maxX: 9, minZ: -48, maxZ: -34, openings: [
            .north(center: 0, width: 4.8),
            .east(center: -41, width: 4.4),
            .west(center: -41, width: 4.2)
        ])
        kit.room(minX: 9, maxX: 28, minZ: -48, maxZ: -34, openings: [
            .west(center: -41, width: 4.4),
            .north(center: 25, width: 4.6)
        ])
        kit.hall(minX: -3.4, maxX: 3.4, minZ: -34, maxZ: -22)
        kit.hall(minX: 22, maxX: 28, minZ: -34, maxZ: 18)
        kit.room(minX: -10, maxX: 12, minZ: -22, maxZ: 10, openings: [
            .south(center: 0, width: 4.8),
            .west(center: 0, width: 4.2),
            .east(center: 4, width: 4.2),
            .north(center: 6, width: 4.6)
        ])
        kit.room(minX: -26, maxX: -9, minZ: -44, maxZ: -34, openings: [
            .east(center: -41, width: 4.2),
            .north(center: -22, width: 4.2)
        ])
        kit.hall(minX: -26, maxX: -18, minZ: -34, maxZ: 8)
        kit.room(minX: -26, maxX: -10, minZ: -4, maxZ: 10, openings: [
            .east(center: 0, width: 4.2),
            .south(center: -22, width: 4.2)
        ])
        kit.room(minX: 4, maxX: 16, minZ: 10, maxZ: 24, openings: [
            .south(center: 6, width: 4.6),
            .east(center: 18, width: 4.4)
        ])
        kit.room(minX: 16, maxX: 36, minZ: 18, maxZ: 40, openings: [
            .south(center: 25, width: 4.6),
            .west(center: 18, width: 4.4),
            .west(center: 32, width: 4.4)
        ])
        kit.room(minX: -2, maxX: 16, minZ: 24, maxZ: 38, openings: [
            .east(center: 32, width: 4.4),
            .south(center: 8, width: 4.4)
        ])
        kit.platform(minX: 5, maxX: 15, minZ: 11.2, maxZ: 23, height: 1.55)
        kit.steps(x: 6, z: 9.2, dx: 0, dz: 1, count: 4, width: 3.2, rise: 0.38, run: 0.7)
        kit.platform(minX: 29, maxX: 35.2, minZ: 32, maxZ: 38.4, height: 1.15)
        kit.steps(x: 28.2, z: 34, dx: 1, dz: 0, count: 3, width: 2.6, rise: 0.38, run: 0.65)
        kit.compound(minX: -28, maxX: 38, minZ: -50, maxZ: 42)
        kit.crate(x: 33, z: 36)
        kit.crate(x: 31.4, z: 36)
        kit.crate(x: 32.2, z: 36, y: 1.5)
        kit.crate(x: 24, z: 36)
        kit.barrel(x: 25, z: -28)
        kit.barrel(x: -22, z: 2)
        kit.pillar(x: 2, z: -6)
        kit.pillar(x: 24, z: 8)
        kit.pipe(from: SIMD3(25, 3.4, -30), to: SIMD3(25, 3.4, 20))
        kit.pipe(from: SIMD3(-22, 3.4, -30), to: SIMD3(-22, 3.4, 6))
        kit.lamps([
            SIMD3(25, 4.6, 28), SIMD3(8, 4.8, 30), SIMD3(0, 4.4, -8),
            SIMD3(25, 4.2, -28), SIMD3(-22, 4.2, -20), SIMD3(10, 5.2, 16)
        ])
        let site = SIMD3<Float>(26, 0, 30)
        let player = SIMD3<Float>(6, 1.64, 30)
        kit.site(at: site)
        return (kit.scene, kit.layout(
            site: site,
            player: player,
            yaw: .pi,
            terrorists: Self.cluster(SIMD3(0, 0, -40), count: 6, alongX: true),
            defenders: Self.cluster(SIMD3(8, 0, 30), count: 6, alongX: true)
        ))
    }

    private static func aztec() -> (SCNScene, MapLayout) {
        let kit = MapKit(
            sky: MapTextures.sky(
                top: NSColor(calibratedRed: 0.34, green: 0.56, blue: 0.80, alpha: 1),
                bottom: NSColor(calibratedRed: 0.72, green: 0.78, blue: 0.70, alpha: 1)
            ),
            fog: NSColor(calibratedRed: 0.58, green: 0.68, blue: 0.70, alpha: 1),
            wall: MapTextures.sandstone,
            ground: MapTextures.sand,
            groundSize: 92
        )
        kit.room(minX: -10, maxX: 10, minZ: -40, maxZ: -24, openings: [.north(center: 0, width: 4.6)])
        kit.hall(minX: -3.2, maxX: 3.2, minZ: -24, maxZ: -10)
        kit.room(minX: -8, maxX: 8, minZ: -10, maxZ: 8, openings: [
            .south(center: 0, width: 4.6),
            .north(center: 0, width: 4.6)
        ])
        kit.water(minX: -6, maxX: 6, minZ: -6, maxZ: 4)
        kit.hall(minX: -3.2, maxX: 3.2, minZ: 8, maxZ: 16)
        kit.room(minX: -26, maxX: 6, minZ: 16, maxZ: 36, openings: [
            .south(center: 0, width: 4.6),
            .east(center: 24, width: 4.4)
        ])
        kit.room(minX: 6, maxX: 26, minZ: 12, maxZ: 30, openings: [.west(center: 24, width: 4.4)])
        kit.platform(minX: -24, maxX: -10, minZ: 22, maxZ: 34, height: 1.4)
        kit.steps(x: -9, z: 26, dx: -1, dz: 0, count: 4, width: 2.8, rise: 0.35, run: 0.7)
        kit.compound(minX: -28, maxX: 28, minZ: -42, maxZ: 38)
        kit.crate(x: -20, z: 30)
        kit.crate(x: 22, z: 22)
        kit.barrel(x: 0, z: -28)
        kit.pillar(x: 0, z: 18)
        kit.pipe(from: SIMD3(0, 3.5, -22), to: SIMD3(0, 3.5, 14))
        kit.lamps([SIMD3(0, 4.8, -32), SIMD3(0, 4.6, -2), SIMD3(-16, 5.4, 26), SIMD3(16, 4.8, 18)])
        let site = SIMD3<Float>(-18, 0, 28)
        let player = SIMD3<Float>(16, 1.64, 18)
        kit.site(at: site)
        return (kit.scene, kit.layout(
            site: site,
            player: player,
            yaw: .pi * 0.7,
            terrorists: Self.cluster(SIMD3(0, 0, -32), count: 6, alongX: true),
            defenders: Self.cluster(SIMD3(14, 0, 16), count: 6, alongX: true)
        ))
    }

    private static func office() -> (SCNScene, MapLayout) {
        let kit = MapKit(
            sky: MapTextures.sky(
                top: NSColor(calibratedRed: 0.32, green: 0.38, blue: 0.46, alpha: 1),
                bottom: NSColor(calibratedRed: 0.52, green: 0.54, blue: 0.56, alpha: 1)
            ),
            fog: NSColor(calibratedRed: 0.42, green: 0.44, blue: 0.46, alpha: 1),
            wall: MapTextures.concrete,
            ground: MapTextures.metal,
            groundSize: 80
        )
        kit.room(minX: -10, maxX: 10, minZ: -36, maxZ: -20, openings: [.north(center: 0, width: 4.2)])
        kit.hall(minX: -2.8, maxX: 2.8, minZ: -20, maxZ: -6)
        kit.room(minX: -8, maxX: 8, minZ: -6, maxZ: 8, openings: [
            .south(center: 0, width: 4.2),
            .north(center: 0, width: 4.2),
            .east(center: 0, width: 4.0)
        ])
        kit.hall(minX: 8, maxX: 22, minZ: -2.6, maxZ: 2.6)
        kit.room(minX: 22, maxX: 32, minZ: -12, maxZ: 8, openings: [.west(center: 0, width: 4.0)])
        kit.hall(minX: -2.8, maxX: 2.8, minZ: 8, maxZ: 16)
        kit.room(minX: -22, maxX: 8, minZ: 16, maxZ: 34, openings: [.south(center: 0, width: 4.2)])
        kit.platform(minX: 24, maxX: 31, minZ: -4, maxZ: 6, height: 1.2)
        kit.compound(minX: -24, maxX: 34, minZ: -38, maxZ: 36)
        kit.crate(x: 26, z: 0, w: 1.6, h: 1.1, d: 2.0)
        kit.crate(x: -16, z: 28)
        kit.barrel(x: 28, z: -8)
        kit.pillar(x: 0, z: 16)
        kit.pipe(from: SIMD3(0, 3.3, -18), to: SIMD3(0, 3.3, 20))
        kit.lamps([SIMD3(0, 4.2, -28), SIMD3(0, 4.2, 0), SIMD3(26, 4.2, -2), SIMD3(-10, 4.4, 24)])
        let site = SIMD3<Float>(-12, 0, 26)
        let player = SIMD3<Float>(2, 1.64, 26)
        kit.site(at: site)
        return (kit.scene, kit.layout(
            site: site,
            player: player,
            yaw: .pi,
            terrorists: Self.cluster(SIMD3(0, 0, -28), count: 6, alongX: true),
            defenders: Self.cluster(SIMD3(2, 0, 24), count: 6, alongX: true)
        ))
    }

    private static func mill() -> (SCNScene, MapLayout) {
        let kit = MapKit(
            sky: MapTextures.sky(
                top: NSColor(calibratedRed: 0.36, green: 0.42, blue: 0.48, alpha: 1),
                bottom: NSColor(calibratedRed: 0.56, green: 0.56, blue: 0.54, alpha: 1)
            ),
            fog: NSColor(calibratedRed: 0.46, green: 0.46, blue: 0.46, alpha: 1),
            wall: MapTextures.concrete,
            ground: MapTextures.metal,
            groundSize: 76
        )
        kit.room(minX: -10, maxX: 10, minZ: -32, maxZ: -16, openings: [.north(center: 0, width: 4.4)])
        kit.hall(minX: -3, maxX: 3, minZ: -16, maxZ: -4)
        kit.room(minX: -14, maxX: 8, minZ: -4, maxZ: 12, openings: [
            .south(center: 0, width: 4.4),
            .north(center: -6, width: 4.4),
            .east(center: 4, width: 4.2)
        ])
        kit.hall(minX: 8, maxX: 20, minZ: 0.8, maxZ: 6.8)
        kit.room(minX: 20, maxX: 30, minZ: -4, maxZ: 16, openings: [.west(center: 4, width: 4.2)])
        kit.room(minX: -22, maxX: 4, minZ: 12, maxZ: 30, openings: [.south(center: -6, width: 4.4)])
        kit.platform(minX: -20, maxX: -8, minZ: 16, maxZ: 28, height: 1.5)
        kit.steps(x: -7, z: 20, dx: -1, dz: 0, count: 4, width: 2.8, rise: 0.37, run: 0.7)
        kit.compound(minX: -24, maxX: 32, minZ: -34, maxZ: 32)
        kit.crate(x: -16, z: 24)
        kit.barrel(x: 24, z: 8)
        kit.pillar(x: -4, z: 4)
        kit.pipe(from: SIMD3(-6, 3.4, -12), to: SIMD3(-6, 3.4, 18))
        kit.lamps([SIMD3(0, 4.4, -24), SIMD3(-6, 4.4, 2), SIMD3(24, 4.4, 6), SIMD3(-14, 5.2, 22)])
        let site = SIMD3<Float>(-14, 0, 22)
        let player = SIMD3<Float>(22, 1.64, 6)
        kit.site(at: site)
        return (kit.scene, kit.layout(
            site: site,
            player: player,
            yaw: .pi * 0.75,
            terrorists: Self.cluster(SIMD3(0, 0, -24), count: 6, alongX: true),
            defenders: Self.cluster(SIMD3(22, 0, 4), count: 6, alongX: true)
        ))
    }

    private static func cluster(_ origin: SIMD3<Float>, count: Int, alongX: Bool) -> [SIMD3<Float>] {
        (0..<count).map { index in
            let offset = (Float(index) - Float(count - 1) / 2) * 1.7
            if alongX {
                return SIMD3(origin.x + offset, 0, origin.z)
            }
            return SIMD3(origin.x, 0, origin.z + offset)
        }
    }
}
