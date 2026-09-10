import AppKit
import Foundation
import simd

struct Cell: Hashable {
    var x: Int
    var z: Int
}

final class GridMap {
    static let size: Float = 2
    private var walk: Set<Cell> = []
    private var rooms: [(x0: Int, x1: Int, z0: Int, z1: Int)] = []

    func fill(x0: Int, x1: Int, z0: Int, z1: Int) {
        let xa = min(x0, x1)
        let xb = max(x0, x1)
        let za = min(z0, z1)
        let zb = max(z0, z1)
        rooms.append((xa, xb, za, zb))
        for x in xa...xb {
            for z in za...zb {
                walk.insert(Cell(x: x, z: z))
            }
        }
    }

    static func world(_ x: Int, _ z: Int) -> SIMD3<Float> {
        SIMD3((Float(x) + 0.5) * size, 0, (Float(z) + 0.5) * size)
    }

    func emit(into kit: MapKit, walkTexture: NSImage, ceiling: NSImage?) {
        let t = GridMap.size
        let thick: Float = 0.72
        let h: Float = 4.2
        for run in merged(missing: { Cell(x: $0.x + 1, z: $0.z) }, line: { $0.x + 1 }, along: { $0.z }) {
            kit.wall(x: Float(run.line) * t, z: mid(run.a, run.b) * t, w: thick, d: Float(run.b - run.a + 1) * t, h: h)
        }
        for run in merged(missing: { Cell(x: $0.x - 1, z: $0.z) }, line: { $0.x }, along: { $0.z }) {
            kit.wall(x: Float(run.line) * t, z: mid(run.a, run.b) * t, w: thick, d: Float(run.b - run.a + 1) * t, h: h)
        }
        for run in merged(missing: { Cell(x: $0.x, z: $0.z + 1) }, line: { $0.z + 1 }, along: { $0.x }) {
            kit.wall(x: mid(run.a, run.b) * t, z: Float(run.line) * t, w: Float(run.b - run.a + 1) * t, d: thick, h: h)
        }
        for run in merged(missing: { Cell(x: $0.x, z: $0.z - 1) }, line: { $0.z }, along: { $0.x }) {
            kit.wall(x: mid(run.a, run.b) * t, z: Float(run.line) * t, w: Float(run.b - run.a + 1) * t, d: thick, h: h)
        }
        for room in rooms {
            let w = Float(room.x1 - room.x0 + 1) * t
            let d = Float(room.z1 - room.z0 + 1) * t
            let x = (Float(room.x0 + room.x1 + 1) * 0.5) * t
            let z = (Float(room.z0 + room.z1 + 1) * 0.5) * t
            kit.slab(x: x, z: z, w: w, d: d, y: 0.02, h: 0.06, texture: walkTexture)
            if let ceiling {
                kit.slab(x: x, z: z, w: w, d: d, y: 4.15, h: 0.12, texture: ceiling)
            }
        }
    }

    private struct Run {
        var line: Int
        var a: Int
        var b: Int
    }

    private func merged(missing: (Cell) -> Cell, line: (Cell) -> Int, along: (Cell) -> Int) -> [Run] {
        var byLine: [Int: [Int]] = [:]
        for cell in walk where !walk.contains(missing(cell)) {
            byLine[line(cell), default: []].append(along(cell))
        }
        var runs: [Run] = []
        for (lineValue, spans) in byLine {
            let sorted = spans.sorted()
            var a = sorted[0]
            var b = sorted[0]
            for value in sorted.dropFirst() {
                if value == b + 1 {
                    b = value
                } else {
                    runs.append(Run(line: lineValue, a: a, b: b))
                    a = value
                    b = value
                }
            }
            runs.append(Run(line: lineValue, a: a, b: b))
        }
        return runs
    }

    private func mid(_ a: Int, _ b: Int) -> Float {
        (Float(a + b) + 1) * 0.5
    }
}
