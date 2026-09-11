import AppKit
import SceneKit

enum MapTextures {
    static let sand = make(size: 512) { x, y, _ in
        let n = noise(x, y)
        let n2 = noise(x * 3, y * 2)
        let grit = CGFloat((x * 17 + y * 11) % 13) * 0.012
        let stain = hash(x / 22, y / 18) < 0.12 ? -0.10 : 0
        let pebble = hash(x, y) < 0.015 ? -0.16 : 0
        return clamp(
            0.62 + n * 0.08 + n2 * 0.04 + grit + stain + pebble,
            0.48 + n * 0.06 + grit * 0.5 + stain,
            0.26 + n * 0.03
        )
    }

    static let sandstone = brick(
        brickW: 48,
        brickH: 18,
        brick: (0.86, 0.62, 0.36),
        mortar: (0.32, 0.24, 0.16),
        dirt: true
    )

    static let aztecStone = brick(
        brickW: 36,
        brickH: 36,
        brick: (0.84, 0.66, 0.42),
        mortar: (0.28, 0.22, 0.14),
        dirt: true
    )

    static let plaster = make(size: 512) { x, y, _ in
        let n = noise(x, y)
        let smear = noise(x / 2, y * 3) * 0.05
        let stain = hash(x / 40, y / 28) < 0.08 ? -0.14 : 0
        let scuff = (x + y * 3) % 97 == 0 ? -0.08 : 0
        return clamp(0.78 + n * 0.04 + smear + stain + scuff, 0.74 + n * 0.03 + stain, 0.66 + n * 0.02)
    }

    static let concrete = make(size: 512) { x, y, _ in
        let n = noise(x, y)
        let n2 = noise(x * 2, y * 2)
        let crack = (x + y) % 61 == 0 || (x * 2 + y) % 89 == 0 ? -0.16 : 0
        let blotch = hash(x / 24, y / 20) < 0.18 ? -0.07 : 0
        let v = 0.46 + n * 0.08 + n2 * 0.03 + crack + blotch
        return clamp(v, v * 0.95, v * 0.86)
    }

    static let rust = make(size: 256) { x, y, _ in
        let n = noise(x, y)
        let rust = hash(x / 8, y / 6)
        let flake = rust > 0.72 ? 0.18 : 0
        return clamp(
            0.28 + n * 0.06 + flake,
            0.18 + n * 0.04 + flake * 0.4,
            0.14 + n * 0.03
        )
    }

    static let crate = make(size: 256) { x, y, size in
        let border = x < 10 || y < 10 || x > size - 11 || y > size - 11
        let plank = (y / 28) % 2 == 0
        let grain = noise(x * 4, y) * 0.06
        let knot = hash(x / 9, y / 9) < 0.02 ? -0.12 : 0
        if border { return clamp(0.22 + grain, 0.13, 0.07) }
        if plank { return clamp(0.62 + grain + knot, 0.40, 0.16) }
        return clamp(0.52 + grain + knot, 0.33, 0.12)
    }

    static let metal = make(size: 128) { x, y, _ in
        let n = noise(x, y)
        let line = y % 16 == 0 ? 0.08 : 0
        let v = 0.34 + n * 0.08 + line
        return clamp(v, v * 1.02, v * 1.08)
    }

    static let carpet = make(size: 256) { x, y, _ in
        let n = noise(x * 3, y * 3)
        let weave = CGFloat((x + y) % 2) * 0.03
        return clamp(0.16 + n * 0.04 + weave, 0.20 + n * 0.03, 0.18 + n * 0.02)
    }

    static let tiles = make(size: 256) { x, y, _ in
        let gx = x % 64
        let gy = y % 64
        let grout = gx <= 3 || gy <= 3
        let n = noise(x, y) * 0.04
        if grout { return clamp(0.42 + n, 0.40, 0.36) }
        return clamp(0.72 + n, 0.70, 0.64)
    }

    static let water = make(size: 128) { x, y, _ in
        let n = noise(x, y)
        let ripple = sin(CGFloat(x) * 0.2 + CGFloat(y) * 0.11) * 0.04
        return clamp(0.14 + n * 0.04, 0.34 + n * 0.05 + ripple, 0.40 + n * 0.06)
    }

    static let hazard = make(size: 128) { x, y, size in
        let stripe = ((x + y) / max(1, size / 6)) % 2 == 0
        if stripe { return (0.90, 0.72, 0.10) }
        return (0.08, 0.07, 0.06)
    }

    static let site = make(size: 256) { x, y, size in
        let edge = x < 8 || y < 8 || x > size - 9 || y > size - 9
        let cross = abs(x - size / 2) < 6 || abs(y - size / 2) < 6
        if edge { return (0.85, 0.78, 0.20) }
        if cross { return (0.72, 0.16, 0.10) }
        return (0.18, 0.18, 0.16)
    }

    static let camoKhaki = camo(a: (0.50, 0.44, 0.28), b: (0.36, 0.32, 0.18), c: (0.62, 0.54, 0.34))
    static let camoSand = camo(a: (0.70, 0.60, 0.38), b: (0.52, 0.44, 0.26), c: (0.38, 0.32, 0.18))
    static let camoOlive = camo(a: (0.28, 0.34, 0.20), b: (0.18, 0.22, 0.12), c: (0.42, 0.40, 0.22))
    static let camoCT = digital(a: (0.12, 0.22, 0.32), b: (0.10, 0.28, 0.24), c: (0.08, 0.10, 0.14))
    static let camoCTDark = digital(a: (0.08, 0.12, 0.18), b: (0.10, 0.16, 0.14), c: (0.06, 0.08, 0.10))
    static let kevlarDark = weave(base: (0.16, 0.16, 0.14))
    static let kevlarTan = weave(base: (0.46, 0.40, 0.28))
    static let kevlarGreen = weave(base: (0.18, 0.24, 0.16))
    static let skinTone = make(size: 128) { x, y, _ in
        let n = noise(x, y) * 0.06
        return clamp(0.76 + n, 0.56 + n * 0.5, 0.42 + n * 0.3)
    }
    static let bootLeather = make(size: 64) { x, y, _ in
        let n = noise(x, y)
        return clamp(0.10 + n * 0.04, 0.08, 0.06)
    }
    static let gunMetal = make(size: 64) { x, y, _ in
        let n = noise(x * 2, y)
        let line = y % 8 == 0 ? 0.06 : 0
        return clamp(0.22 + n * 0.05 + line, 0.22, 0.20)
    }
    static let gunWood = make(size: 64) { x, y, _ in
        let grain = noise(x * 4, y) * 0.08
        return clamp(0.42 + grain, 0.26 + grain * 0.4, 0.12)
    }

    static func sky(top: NSColor, bottom: NSColor, clouds: Bool = true) -> NSImage {
        make(size: 512) { x, y, size in
            var tr: CGFloat = 0, tg: CGFloat = 0, tb: CGFloat = 0, a: CGFloat = 0
            var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0
            top.getRed(&tr, green: &tg, blue: &tb, alpha: &a)
            bottom.getRed(&br, green: &bg, blue: &bb, alpha: &a)
            let t = pow(CGFloat(y) / CGFloat(size - 1), 0.75)
            var r = br + (tr - br) * t
            var g = bg + (tg - bg) * t
            var b = bb + (tb - bb) * t
            if clouds && y > size / 2 {
                let puff = noise(x / 3, y / 2)
                if puff > 0.62 {
                    let w = (puff - 0.62) * 1.6
                    r += (0.92 - r) * w
                    g += (0.90 - g) * w
                    b += (0.86 - b) * w
                }
            }
            let sun = hypot(CGFloat(x - 410), CGFloat(y - 430))
            if sun < 28 {
                return (1, 0.95, 0.72)
            }
            return clamp(r, g, b)
        }
    }

    static func skyBox(from image: NSImage) -> [NSImage] {
        let dark = make(size: 128) { _, _, _ in (0.18, 0.16, 0.12) }
        return [image, image, image, dark, image, image]
    }

    static func goldSrc(_ contents: Any) -> SCNMaterial {
        phong(contents, spec: 0.05, shine: 8)
    }

    static func metalSrc(_ contents: Any) -> SCNMaterial {
        phong(contents, spec: 0.22, shine: 24)
    }

    private static func phong(_ contents: Any, spec: CGFloat, shine: CGFloat) -> SCNMaterial {
        let mat = SCNMaterial()
        mat.lightingModel = .phong
        mat.diffuse.contents = contents
        mat.diffuse.wrapS = .repeat
        mat.diffuse.wrapT = .repeat
        mat.diffuse.magnificationFilter = .linear
        mat.diffuse.minificationFilter = .linear
        mat.diffuse.mipFilter = .linear
        mat.specular.contents = NSColor(white: spec, alpha: 1)
        mat.shininess = shine
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

    private static func brick(
        brickW: Int,
        brickH: Int,
        brick: (CGFloat, CGFloat, CGFloat),
        mortar: (CGFloat, CGFloat, CGFloat),
        dirt: Bool
    ) -> NSImage {
        make(size: 512) { x, y, _ in
            let row = y / brickH
            let shift = (row % 2) * (brickW / 2)
            let gx = (x + shift) % brickW
            let gy = y % brickH
            let inMortar = gx <= 2 || gy <= 2
            let n = noise(x + row * 5, y)
            let chip = hash(x / 3, y / 3) < 0.03 ? -0.14 : 0
            let stain = dirt && hash(x / 14, y / 12) < 0.15 ? -0.10 : 0
            if inMortar { return clamp(mortar.0 + n * 0.03, mortar.1, mortar.2) }
            return clamp(
                brick.0 + n * 0.06 + chip + stain,
                brick.1 + n * 0.04 + chip * 0.5,
                brick.2 + n * 0.03
            )
        }
    }

    private static func make(size: Int, paint: (Int, Int, Int) -> (CGFloat, CGFloat, CGFloat)) -> NSImage {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: size,
            pixelsHigh: size,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: size * 4,
            bitsPerPixel: 32
        )!
        guard let data = rep.bitmapData else { return NSImage() }
        for y in 0..<size {
            for x in 0..<size {
                let c = paint(x, y, size)
                let i = (y * size + x) * 4
                data[i] = byte(c.0)
                data[i + 1] = byte(c.1)
                data[i + 2] = byte(c.2)
                data[i + 3] = 255
            }
        }
        let image = NSImage(size: NSSize(width: size, height: size))
        image.addRepresentation(rep)
        return image
    }

    private static func camo(
        a: (CGFloat, CGFloat, CGFloat),
        b: (CGFloat, CGFloat, CGFloat),
        c: (CGFloat, CGFloat, CGFloat)
    ) -> NSImage {
        make(size: 256) { x, y, _ in
            let blob = hash(x / 10, y / 8)
            let n = noise(x / 2, y / 2)
            if blob < 0.28 { return clamp(b.0 + n * 0.04, b.1, b.2) }
            if blob > 0.72 { return clamp(c.0 + n * 0.04, c.1, c.2) }
            return clamp(a.0 + n * 0.05, a.1, a.2)
        }
    }

    private static func digital(
        a: (CGFloat, CGFloat, CGFloat),
        b: (CGFloat, CGFloat, CGFloat),
        c: (CGFloat, CGFloat, CGFloat)
    ) -> NSImage {
        make(size: 256) { x, y, _ in
            let cell = hash(x / 8, y / 8)
            if cell < 0.33 { return a }
            if cell < 0.66 { return b }
            return c
        }
    }

    private static func weave(base: (CGFloat, CGFloat, CGFloat)) -> NSImage {
        make(size: 128) { x, y, _ in
            let stitch = CGFloat((x + y) % 4) * 0.02
            let n = noise(x, y) * 0.04
            return clamp(base.0 + stitch + n, base.1 + stitch * 0.5, base.2)
        }
    }

    private static func clamp(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> (CGFloat, CGFloat, CGFloat) {
        (max(0, min(1, r)), max(0, min(1, g)), max(0, min(1, b)))
    }

    private static func noise(_ x: Int, _ y: Int) -> CGFloat {
        let v = sin(CGFloat(x) * 0.37 + CGFloat(y) * 0.19) * 0.5
            + sin(CGFloat(x) * 0.11 - CGFloat(y) * 0.29) * 0.5
        return (v + 1) * 0.5
    }

    private static func byte(_ v: CGFloat) -> UInt8 {
        UInt8(clamping: Int((max(0, min(1, v)) * 255).rounded()))
    }

    private static func hash(_ x: Int, _ y: Int) -> CGFloat {
        var n = UInt32(truncatingIfNeeded: x &* 374_761_393 &+ y &* 668_265_263)
        n = (n ^ (n >> 13)) &* 1_274_126_177
        return CGFloat(n % 1000) / 1000
    }
}
