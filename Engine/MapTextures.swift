import AppKit
import SceneKit

enum MapTextures {
    static let sand = make(size: 256) { x, y, _ in
        let n = noise(x, y)
        let grit = CGFloat((x * 17 + y * 11) % 9) * 0.018
        let stain = ((x / 18) + (y / 22)) % 3 == 0 ? -0.08 : 0
        let pebble = (x * 13 + y * 7) % 29 == 0 ? -0.10 : 0
        return (0.58 + n * 0.10 + grit + stain + pebble, 0.44 + n * 0.07 + grit * 0.6, 0.22 + n * 0.04)
    }

    static let sandstone = make(size: 256) { x, y, _ in
        let brickW = 32
        let brickH = 14
        let gx = x % brickW
        let gy = y % brickH
        let row = y / brickH
        let shift = (row % 2) * (brickW / 2)
        let inMortar = ((x + shift) % brickW) <= 2 || gy <= 2
        let n = noise(x + row * 3, y)
        let chip = (gx == 6 && gy == 4) || (gx == 22 && gy == 9) ? -0.12 : 0
        let dirt = ((x / 9) + (y / 11)) % 5 == 0 ? -0.07 : 0
        if inMortar { return (0.42, 0.32, 0.22) }
        return (0.74 + n * 0.05 + chip + dirt * 0.5, 0.58 + n * 0.04, 0.38 + n * 0.03)
    }

    static let crate = make(size: 256) { x, y, size in
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

    static let concrete = make(size: 256) { x, y, _ in
        let n = noise(x, y)
        let crack = (x + y) % 41 == 0 || (x * 2 + y) % 73 == 0 ? -0.12 : 0
        let blotch = ((x / 20) + (y / 16)) % 4 == 0 ? -0.05 : 0
        let v = 0.40 + n * 0.10 + crack + blotch
        return (v, v * 0.96, v * 0.88)
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
        let size = 256
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        var tr: CGFloat = 0, tg: CGFloat = 0, tb: CGFloat = 0, ta: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        top.getRed(&tr, green: &tg, blue: &tb, alpha: &ta)
        bottom.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        for y in 0..<size {
            let t = pow(CGFloat(y) / CGFloat(size - 1), 0.85)
            NSColor(
                calibratedRed: br + (tr - br) * t,
                green: bg + (tg - bg) * t,
                blue: bb + (tb - bb) * t,
                alpha: 1
            ).setFill()
            NSRect(x: 0, y: y, width: size, height: 1).fill()
        }
        NSColor(calibratedRed: 1, green: 0.93, blue: 0.72, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: 168, y: 188, width: 28, height: 28)).fill()
        image.unlockFocus()
        return image
    }

    static func goldSrc(_ contents: Any) -> SCNMaterial {
        let mat = SCNMaterial()
        mat.lightingModel = .blinn
        mat.diffuse.contents = contents
        mat.diffuse.wrapS = .repeat
        mat.diffuse.wrapT = .repeat
        mat.diffuse.magnificationFilter = .linear
        mat.diffuse.minificationFilter = .linear
        mat.diffuse.mipFilter = .linear
        mat.specular.contents = NSColor(calibratedWhite: 0.06, alpha: 1)
        mat.shininess = 4
        mat.locksAmbientWithDiffuse = true
        mat.isDoubleSided = true
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
