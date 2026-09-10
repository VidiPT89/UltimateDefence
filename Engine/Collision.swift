import Foundation
import simd

struct AABB {
    var minX: Float
    var maxX: Float
    var minZ: Float
    var maxZ: Float

    func expanded(_ margin: Float) -> AABB {
        AABB(minX: minX - margin, maxX: maxX + margin, minZ: minZ - margin, maxZ: maxZ + margin)
    }

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
            if box.contains(x: x, z: z) {
                let px = position.x
                let pz = position.z
                if !box.contains(x: x, z: pz) {
                    z = pz
                } else if !box.contains(x: px, z: z) {
                    x = px
                } else {
                    x = px
                    z = pz
                }
            }
        }
        return SIMD3(x, position.y, z)
    }

    static func distanceXZ(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
        hypot(a.x - b.x, a.z - b.z)
    }
}
