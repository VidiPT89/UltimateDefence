import AppKit
import SceneKit

enum MapTextures {
    static let sand = make(size: 128) { x, y, _ in
        let n = noise(x, y)
        let pebble = ((x * 13 + y * 7) % 17 == 0) ? 0.08 : 0
        return (0.70 + n * 0.10 + pebble, 0.56 + n * 0.07, 0.30 + n * 0.05)
    }

    static let sandstone = make(size: 128) { x, y, _ in
        let brickW = 32
        let brickH = 14
        let gy = y % brickH
        let row = y / brickH
        let shift = (row % 2) * (brickW / 2)
        let inMortar = ((x + shift) % brickW) <= 1 || gy <= 1
        let n = noise(x, y)
        if inMortar { return (0.42, 0.32, 0.20) }
        return (0.78 + n * 0.06, 0.62 + n * 0.05, 0.38 + n * 0.04)
    }

    static let crate = make(size: 128) { x, y, size in
        let border = x < 6 || y < 6 || x > size - 7 || y > size - 7
        let plank = (y / 16) % 2 == 0
        let n = noise(x, y) * 0.04
        if border { return (0.28 + n, 0.16, 0.08) }
        if plank { return (0.58 + n, 0.38, 0.16) }
        return (0.50 + n, 0.32, 0.12)
    }

    static let metal = make(size: 64) { x, y, _ in
        let n = noise(x, y)
        let v = 0.32 + n * 0.10
        return (v, v * 1.02, v * 1.06)
    }

    static let concrete = make(size: 128) { x, y, _ in
        let n = noise(x, y)
        let crack = (x + y) % 41 == 0 ? -0.08 : 0
        let v = 0.46 + n * 0.08 + crack
        return (v, v * 0.97, v * 0.90)
    }

    static let wood = make(size: 128) { x, y, _ in
        let n = noise(x, y)
        let grain = sin(CGFloat(y) * 0.4) * 0.04
        return (0.46 + n * 0.05 + grain, 0.30 + n * 0.04, 0.14)
    }

    static let water = make(size: 64) { x, y, _ in
        let n = noise(x, y)
        return (0.18 + n * 0.05, 0.32 + n * 0.06, 0.38 + n * 0.08)
    }

    static let hazard = make(size: 64) { x, y, size in
        let stripe = ((x + y) / max(1, size / 6)) % 2 == 0
        if stripe { return (0.88, 0.68, 0.14) }
        return (0.10, 0.09, 0.07)
    }

    static func sky(top: NSColor, bottom: NSColor) -> NSImage {
        let size = 64
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        var tr: CGFloat = 0, tg: CGFloat = 0, tb: CGFloat = 0, ta: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        top.getRed(&tr, green: &tg, blue: &tb, alpha: &ta)
        bottom.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        for y in 0..<size {
            let t = CGFloat(y) / CGFloat(size - 1)
            NSColor(
                calibratedRed: br + (tr - br) * t,
                green: bg + (tg - bg) * t,
                blue: bb + (tb - bb) * t,
                alpha: 1
            ).setFill()
            NSRect(x: 0, y: y, width: size, height: 1).fill()
        }
        image.unlockFocus()
        return image
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
        mat.isDoubleSided = false
        mat.writesToDepthBuffer = true
        mat.readsFromDepthBuffer = true
        return mat
    }

    static func tiled(_ contents: Any, repeatU: CGFloat, repeatV: CGFloat) -> SCNMaterial {
        let mat = goldSrc(contents)
        mat.diffuse.contentsTransform = SCNMatrix4MakeScale(max(1, repeatU), max(1, repeatV), 1)
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
