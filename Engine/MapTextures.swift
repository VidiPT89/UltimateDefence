import AppKit
import SceneKit

enum MapTextures {
    static let sand = make(size: 64) { x, y, _ in
        let n = noise(x, y)
        return (0.72 + n * 0.08, 0.58 + n * 0.06, 0.32 + n * 0.04)
    }

    static let sandstone = make(size: 64) { x, y, _ in
        let n = noise(x, y)
        let mortar = x % 16 == 0 || y % 8 == 0
        if mortar { return (0.42, 0.34, 0.22) }
        return (0.78 + n * 0.06, 0.62 + n * 0.05, 0.38)
    }

    static let crate = make(size: 64) { x, y, size in
        let border = x < 3 || y < 3 || x > size - 4 || y > size - 4
        let plank = (y / 8) % 2 == 0
        if border { return (0.22, 0.14, 0.08) }
        if plank { return (0.55, 0.35, 0.16) }
        return (0.48, 0.30, 0.12)
    }

    static let metal = make(size: 32) { x, y, _ in
        let n = noise(x, y)
        let v = 0.28 + n * 0.08
        return (v, v * 1.02, v * 1.05)
    }

    static let concrete = make(size: 64) { x, y, _ in
        let n = noise(x, y)
        let v = 0.42 + n * 0.08
        return (v, v * 0.96, v * 0.88)
    }

    static let rust = make(size: 64) { x, y, _ in
        let n = noise(x, y)
        return (0.48 + n * 0.1, 0.28 + n * 0.05, 0.12)
    }

    static let hazard = make(size: 32) { x, y, size in
        let stripe = ((x + y) / max(1, size / 4)) % 2 == 0
        if stripe { return (0.85, 0.62, 0.12) }
        return (0.12, 0.10, 0.08)
    }

    static func goldSrc(_ contents: Any) -> SCNMaterial {
        let mat = SCNMaterial()
        mat.lightingModel = .lambert
        mat.diffuse.contents = contents
        mat.diffuse.wrapS = .repeat
        mat.diffuse.wrapT = .repeat
        mat.diffuse.magnificationFilter = .nearest
        mat.diffuse.minificationFilter = .nearest
        mat.locksAmbientWithDiffuse = true
        return mat
    }

    private static func make(size: Int, paint: (Int, Int, Int) -> (CGFloat, CGFloat, CGFloat)) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        for y in 0..<size {
            for x in 0..<size {
                let c = paint(x, y, size)
                NSColor(calibratedRed: c.0, green: c.1, blue: c.2, alpha: 1).setFill()
                NSRect(x: x, y: y, width: 1, height: 1).fill()
            }
        }
        image.unlockFocus()
        return image
    }

    private static func noise(_ x: Int, _ y: Int) -> CGFloat {
        let v = sin(CGFloat(x) * 0.37 + CGFloat(y) * 0.19) * 0.5
            + sin(CGFloat(x) * 0.11 - CGFloat(y) * 0.29) * 0.5
        return (v + 1) * 0.5
    }
}
