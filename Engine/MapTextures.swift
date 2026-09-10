import AppKit

enum MapTextures {
    static let concrete = make(size: 128) { x, y, _ in
        let n = noise(x, y)
        let v = 0.18 + n * 0.08
        return (v, v * 0.96, v * 0.88)
    }

    static let rust = make(size: 128) { x, y, _ in
        let n = noise(x, y)
        return (0.42 + n * 0.12, 0.20 + n * 0.06, 0.10)
    }

    static let hazard = make(size: 64) { x, y, size in
        let stripe = ((x + y) / max(1, size / 8)) % 2 == 0
        if stripe { return (0.98, 0.61, 0.0) }
        return (0.04, 0.04, 0.06)
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
