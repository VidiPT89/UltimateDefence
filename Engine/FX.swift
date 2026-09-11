import SceneKit
import AppKit

enum FX {
    static func spark(at position: SCNVector3, in parent: SCNNode, color: NSColor) {
        let geom = SCNSphere(radius: 0.06)
        let mat = SCNMaterial()
        mat.diffuse.contents = color
        mat.emission.contents = color
        mat.lightingModel = .constant
        geom.firstMaterial = mat
        let node = SCNNode(geometry: geom)
        node.position = position
        parent.addChildNode(node)
        let grow = SCNAction.scale(to: 3.2, duration: 0.08)
        let fade = SCNAction.fadeOut(duration: 0.18)
        node.runAction(.sequence([.group([grow, fade]), .removeFromParentNode()]))
    }

    static func tracer(from: SCNVector3, to: SCNVector3, in parent: SCNNode) {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let dz = to.z - from.z
        let length = sqrt(dx * dx + dy * dy + dz * dz)
        guard length > 0.4 else { return }
        let cyl = SCNCylinder(radius: 0.012, height: length)
        let mat = SCNMaterial()
        mat.diffuse.contents = NSColor(calibratedRed: 1, green: 0.82, blue: 0.35, alpha: 1)
        mat.emission.contents = NSColor(calibratedRed: 1, green: 0.7, blue: 0.2, alpha: 1)
        mat.lightingModel = .constant
        cyl.firstMaterial = mat
        let node = SCNNode(geometry: cyl)
        node.position = SCNVector3((from.x + to.x) / 2, (from.y + to.y) / 2, (from.z + to.z) / 2)
        node.look(at: to)
        node.eulerAngles.x += .pi / 2
        parent.addChildNode(node)
        node.runAction(.sequence([.fadeOut(duration: 0.08), .removeFromParentNode()]))
    }

    static func explosion(at position: SCNVector3, in parent: SCNNode) {
        spark(at: position, in: parent, color: NSColor(calibratedRed: 1, green: 0.5, blue: 0.12, alpha: 1))
        let wave = SCNSphere(radius: 0.4)
        let mat = SCNMaterial()
        mat.diffuse.contents = NSColor(calibratedRed: 1, green: 0.4, blue: 0.1, alpha: 0.4)
        mat.emission.contents = NSColor(calibratedRed: 1, green: 0.55, blue: 0.15, alpha: 1)
        mat.lightingModel = .constant
        wave.firstMaterial = mat
        let node = SCNNode(geometry: wave)
        node.position = position
        parent.addChildNode(node)
        node.runAction(.sequence([
            .group([.scale(to: 14, duration: 0.45), .fadeOut(duration: 0.45)]),
            .removeFromParentNode()
        ]))
    }
}

enum WeaponRig {
    static func attach(to camera: SCNNode, slot: WeaponSlot) {
        camera.childNode(withName: "weaponRig", recursively: false)?.removeFromParentNode()
        let root = SCNNode()
        root.name = "weaponRig"
        switch slot {
        case .rifle:
            root.addChildNode(box(0.09, 0.08, 0.16, x: 0.08, y: -0.2, z: -0.24, color: skin))
            root.addChildNode(box(0.1, 0.07, 0.14, x: 0.2, y: -0.19, z: -0.2, color: glove))
            root.addChildNode(box(0.05, 0.055, 0.18, x: 0.2, y: -0.15, z: -0.16, color: wood))
            root.addChildNode(box(0.07, 0.085, 0.22, x: 0.2, y: -0.145, z: -0.32, color: dark, metal: true))
            root.addChildNode(box(0.055, 0.06, 0.28, x: 0.2, y: -0.15, z: -0.52, color: wood))
            root.addChildNode(cyl(0.012, 0.42, x: 0.2, y: -0.13, z: -0.82, color: steel))
            root.addChildNode(box(0.018, 0.018, 0.08, x: 0.2, y: -0.13, z: -0.98, color: dark, metal: true))
            root.addChildNode(box(0.02, 0.07, 0.03, x: 0.2, y: -0.08, z: -0.72, color: dark, metal: true))
            root.addChildNode(box(0.045, 0.16, 0.07, x: 0.2, y: -0.24, z: -0.38, color: dark, metal: true))
            root.addChildNode(box(0.038, 0.12, 0.06, x: 0.2, y: -0.26, z: -0.36, color: wood))
            root.addChildNode(box(0.04, 0.12, 0.055, x: 0.2, y: -0.22, z: -0.28, color: dark, metal: true))
            root.addChildNode(box(0.08, 0.05, 0.09, x: 0.08, y: -0.17, z: -0.42, color: glove))
        case .pistol:
            root.addChildNode(box(0.08, 0.07, 0.14, x: 0.16, y: -0.18, z: -0.26, color: skin))
            root.addChildNode(box(0.048, 0.055, 0.22, x: 0.18, y: -0.135, z: -0.42, color: steel, metal: true))
            root.addChildNode(box(0.04, 0.14, 0.055, x: 0.18, y: -0.24, z: -0.28, color: dark, metal: true))
            root.addChildNode(box(0.03, 0.025, 0.06, x: 0.18, y: -0.11, z: -0.5, color: dark, metal: true))
            root.addChildNode(box(0.07, 0.05, 0.07, x: 0.12, y: -0.16, z: -0.32, color: glove))
        }
        camera.addChildNode(root)
    }

    static func kick(_ camera: SCNNode) {
        guard let rig = camera.childNode(withName: "weaponRig", recursively: false) else { return }
        rig.removeAllActions()
        let back = SCNAction.moveBy(x: 0, y: 0.012, z: 0.035, duration: 0.04)
        let rest = SCNAction.moveBy(x: 0, y: -0.012, z: -0.035, duration: 0.09)
        back.timingMode = .easeOut
        rest.timingMode = .easeInEaseOut
        rig.runAction(.sequence([back, rest]))
    }

    private static let steel = NSColor(calibratedRed: 0.28, green: 0.28, blue: 0.26, alpha: 1)
    private static let dark = NSColor(calibratedRed: 0.08, green: 0.08, blue: 0.07, alpha: 1)
    private static let wood = NSColor(calibratedRed: 0.38, green: 0.24, blue: 0.12, alpha: 1)
    private static let skin = NSColor(calibratedRed: 0.72, green: 0.54, blue: 0.42, alpha: 1)
    private static let glove = NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.1, alpha: 1)

    private static func box(
        _ w: CGFloat,
        _ h: CGFloat,
        _ l: CGFloat,
        x: CGFloat,
        y: CGFloat,
        z: CGFloat,
        color: NSColor,
        metal: Bool = false
    ) -> SCNNode {
        let g = SCNBox(width: w, height: h, length: l, chamferRadius: 0.006)
        g.firstMaterial = metal ? MapTextures.metalSrc(color) : MapTextures.goldSrc(color)
        let n = SCNNode(geometry: g)
        n.position = SCNVector3(x, y, z)
        return n
    }

    private static func cyl(_ r: CGFloat, _ h: CGFloat, x: CGFloat, y: CGFloat, z: CGFloat, color: NSColor) -> SCNNode {
        let g = SCNCylinder(radius: r, height: h)
        g.radialSegmentCount = 10
        g.firstMaterial = MapTextures.metalSrc(color)
        let n = SCNNode(geometry: g)
        n.position = SCNVector3(x, y, z)
        n.eulerAngles.x = .pi / 2
        return n
    }
}
