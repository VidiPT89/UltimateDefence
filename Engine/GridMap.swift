import Foundation
import simd

struct Cell: Hashable {
    var x: Int
    var z: Int
}

final class GridMap {
    static let size: Float = 2
    private var walk: Set<Cell> = []

    func fill(x0: Int, x1: Int, z0: Int, z1: Int) {
        let xs = min(x0, x1)...max(x0, x1)
        let zs = min(z0, z1)...max(z0, z1)
        for x in xs {
            for z in zs {
                walk.insert(Cell(x: x, z: z))
            }
        }
    }

    static func world(_ x: Int, _ z: Int) -> SIMD3<Float> {
        SIMD3((Float(x) + 0.5) * size, 0, (Float(z) + 0.5) * size)
    }

    func emit(into kit: MapKit) {
        let t = GridMap.size
        let thick: Float = 0.7
        let h: Float = 4.0
        for cell in walk {
            if !walk.contains(Cell(x: cell.x + 1, z: cell.z)) {
                kit.wall(x: Float(cell.x + 1) * t, z: (Float(cell.z) + 0.5) * t, w: thick, d: t, h: h)
            }
            if !walk.contains(Cell(x: cell.x - 1, z: cell.z)) {
                kit.wall(x: Float(cell.x) * t, z: (Float(cell.z) + 0.5) * t, w: thick, d: t, h: h)
            }
            if !walk.contains(Cell(x: cell.x, z: cell.z + 1)) {
                kit.wall(x: (Float(cell.x) + 0.5) * t, z: Float(cell.z + 1) * t, w: t, d: thick, h: h)
            }
            if !walk.contains(Cell(x: cell.x, z: cell.z - 1)) {
                kit.wall(x: (Float(cell.x) + 0.5) * t, z: Float(cell.z) * t, w: t, d: thick, h: h)
            }
        }
    }
}
