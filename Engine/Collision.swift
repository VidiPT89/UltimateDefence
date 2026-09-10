import Foundation
import simd

struct AABB {
    var minX: Float
    var maxX: Float
    var minZ: Float
    var maxZ: Float
    var blocksSight: Bool = true

    func expanded(_ margin: Float) -> AABB {
        AABB(minX: minX - margin, maxX: maxX + margin, minZ: minZ - margin, maxZ: maxZ + margin, blocksSight: blocksSight)
    }

    func contains(x: Float, z: Float) -> Bool {
        x >= minX && x <= maxX && z >= minZ && z <= maxZ
    }
}

struct Platform {
    var minX: Float
    var maxX: Float
    var minZ: Float
    var maxZ: Float
    var height: Float

    func contains(x: Float, z: Float) -> Bool {
        x >= minX && x <= maxX && z >= minZ && z <= maxZ
    }
}

enum Collision {
    static func resolve(position: SIMD3<Float>, proposed: SIMD3<Float>, radius: Float, walls: [AABB]) -> SIMD3<Float> {
        var x = proposed.x
        var z = proposed.z
        for wall in walls {
            let box = wall.expanded(radius)
            guard box.contains(x: x, z: z) else { continue }
            let left = x - box.minX
            let right = box.maxX - x
            let south = z - box.minZ
            let north = box.maxZ - z
            let smallest = min(left, right, south, north)
            if smallest == left {
                x = box.minX - 0.001
            } else if smallest == right {
                x = box.maxX + 0.001
            } else if smallest == south {
                z = box.minZ - 0.001
            } else {
                z = box.maxZ + 0.001
            }
        }
        if isBlocked(SIMD3(x, position.y, z), radius: radius, walls: walls) {
            return unstick(SIMD3(x, position.y, z), radius: radius, walls: walls)
        }
        return SIMD3(x, position.y, z)
    }

    static func distanceXZ(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
        hypot(a.x - b.x, a.z - b.z)
    }

    static func isBlocked(_ position: SIMD3<Float>, radius: Float, walls: [AABB]) -> Bool {
        walls.contains { $0.expanded(radius).contains(x: position.x, z: position.z) }
    }

    static func unstick(_ position: SIMD3<Float>, radius: Float, walls: [AABB]) -> SIMD3<Float> {
        var x = position.x
        var z = position.z
        for _ in 0..<12 {
            var moved = false
            for wall in walls {
                let box = wall.expanded(radius)
                guard box.contains(x: x, z: z) else { continue }
                let left = x - box.minX
                let right = box.maxX - x
                let south = z - box.minZ
                let north = box.maxZ - z
                let smallest = min(left, right, south, north)
                if smallest == left {
                    x = box.minX - 0.02
                } else if smallest == right {
                    x = box.maxX + 0.02
                } else if smallest == south {
                    z = box.minZ - 0.02
                } else {
                    z = box.maxZ + 0.02
                }
                moved = true
            }
            if !moved { break }
        }
        return SIMD3(x, position.y, z)
    }

    static func floorHeight(x: Float, z: Float, floors: [Platform]) -> Float {
        floors.reduce(0) { best, pad in
            pad.contains(x: x, z: z) ? max(best, pad.height) : best
        }
    }

    static func losClear(_ from: SIMD3<Float>, _ to: SIMD3<Float>, walls: [AABB]) -> Bool {
        !walls.contains { wall in
            guard wall.blocksSight else { return false }
            if wall.contains(x: from.x, z: from.z) || wall.contains(x: to.x, z: to.z) {
                return false
            }
            return segmentHits(wall, from: from, to: to)
        }
    }

    static func segmentHits(_ box: AABB, from: SIMD3<Float>, to: SIMD3<Float>) -> Bool {
        let dx = to.x - from.x
        let dz = to.z - from.z
        var tMin: Float = 0
        var tMax: Float = 1
        if !clip(from.x, dx, box.minX, box.maxX, &tMin, &tMax) { return false }
        if !clip(from.z, dz, box.minZ, box.maxZ, &tMin, &tMax) { return false }
        return tMax >= tMin
    }

    private static func clip(
        _ start: Float,
        _ delta: Float,
        _ minB: Float,
        _ maxB: Float,
        _ tMin: inout Float,
        _ tMax: inout Float
    ) -> Bool {
        if abs(delta) < 0.0001 {
            return start >= minB && start <= maxB
        }
        let t1 = (minB - start) / delta
        let t2 = (maxB - start) / delta
        let near = min(t1, t2)
        let far = max(t1, t2)
        tMin = max(tMin, near)
        tMax = min(tMax, far)
        return tMin <= tMax
    }
}
