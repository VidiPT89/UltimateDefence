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

    static func dustField() -> SCNParticleSystem {
        let dust = SCNParticleSystem()
        dust.birthRate = 18
        dust.particleLifeSpan = 7
        dust.particleSize = 0.07
        dust.particleColor = NSColor(calibratedWhite: 0.55, alpha: 0.18)
        dust.spreadingAngle = 180
        dust.particleVelocity = 0.15
        dust.emitterShape = SCNBox(width: 50, height: 6, length: 50, chamferRadius: 0)
        dust.blendMode = .additive
        return dust
    }

    static func siteEmbers() -> SCNParticleSystem {
        let embers = SCNParticleSystem()
        embers.birthRate = 10
        embers.particleLifeSpan = 1.8
        embers.particleSize = 0.05
        embers.particleColor = NSColor(calibratedRed: 1, green: 0.45, blue: 0.08, alpha: 0.7)
        embers.spreadingAngle = 80
        embers.particleVelocity = 0.55
        embers.emitterShape = SCNCylinder(radius: 3.8, height: 0.2)
        embers.blendMode = .additive
        return embers
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
            root.addChildNode(box(0.08, 0.08, 0.68, x: 0.22, y: -0.18, z: -0.46, color: steel))
            root.addChildNode(box(0.09, 0.11, 0.28, x: 0.22, y: -0.16, z: -0.22, color: dark))
            root.addChildNode(box(0.07, 0.16, 0.18, x: 0.22, y: -0.28, z: -0.2, color: dark))
            root.addChildNode(box(0.05, 0.18, 0.07, x: 0.22, y: -0.34, z: -0.32, color: steel))
            root.addChildNode(box(0.035, 0.035, 0.18, x: 0.22, y: -0.11, z: -0.68, color: ember))
            root.addChildNode(box(0.02, 0.05, 0.05, x: 0.22, y: -0.08, z: -0.38, color: ember))
        case .pistol:
            root.addChildNode(box(0.06, 0.08, 0.24, x: 0.18, y: -0.16, z: -0.34, color: steel))
            root.addChildNode(box(0.05, 0.16, 0.08, x: 0.18, y: -0.28, z: -0.24, color: dark))
            root.addChildNode(box(0.03, 0.03, 0.08, x: 0.18, y: -0.12, z: -0.46, color: ember))
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

    private static let steel = NSColor(calibratedRed: 0.42, green: 0.45, blue: 0.48, alpha: 1)
    private static let dark = NSColor(calibratedRed: 0.12, green: 0.13, blue: 0.14, alpha: 1)
    private static let ember = NSColor(calibratedRed: 0.976, green: 0.612, blue: 0, alpha: 1)

    private static func box(_ w: CGFloat, _ h: CGFloat, _ l: CGFloat, x: CGFloat, y: CGFloat, z: CGFloat, color: NSColor) -> SCNNode {
        let g = SCNBox(width: w, height: h, length: l, chamferRadius: 0.008)
        let m = SCNMaterial()
        m.diffuse.contents = color
        m.metalness.contents = 0.65
        m.roughness.contents = 0.28
        m.lightingModel = .physicallyBased
        g.firstMaterial = m
        let n = SCNNode(geometry: g)
        n.position = SCNVector3(x, y, z)
        return n
    }
}
