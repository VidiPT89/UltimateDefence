import SceneKit
import AppKit

enum CharacterMesh {
    static func attach(to root: SCNNode, team: BotTeam, variant: Int, name: String, headName: String) {
        let look = palette(team: team, variant: variant)
        let hips = capsule(0.16, 0.22, at: SCNVector3(0, 0.96, 0.02), tex: look.pants)
        root.addChildNode(hips)

        leg(root, x: -0.12, pants: look.pants, boot: look.boot)
        leg(root, x: 0.12, pants: look.pants, boot: look.boot)

        let chest = capsule(0.20, 0.52, at: SCNVector3(0, 1.34, 0.03), tex: look.shirt)
        chest.name = name
        chest.scale = SCNVector3(1.12, 1, 0.78)
        root.addChildNode(chest)

        if look.vest {
            let vest = box(0.46, 0.32, 0.28, at: SCNVector3(0, 1.30, 0.06), tex: look.vestTex)
            root.addChildNode(vest)
            pouch(root, x: -0.12, tex: look.vestTex)
            pouch(root, x: 0.12, tex: look.vestTex)
        }

        let neck = cylinder(0.055, 0.1, at: SCNVector3(0, 1.58, 0.03), tex: look.skin)
        root.addChildNode(neck)
        let headGeom = SCNSphere(radius: 0.115)
        headGeom.segmentCount = 18
        headGeom.firstMaterial = MapTextures.goldSrc(look.skin)
        let head = SCNNode(geometry: headGeom)
        head.name = headName
        head.position = SCNVector3(0, 1.70, 0.04)
        head.scale = SCNVector3(0.92, 1.08, 1.02)
        root.addChildNode(head)
        addFace(head, skin: look.skin)
        addHeadgear(head, look: look)

        arm(root, side: -1, look: look)
        arm(root, side: 1, look: look)
        rifle(root, look: look)
    }

    private struct Look {
        let skin: NSImage
        let shirt: NSImage
        let pants: NSImage
        let boot: NSImage
        let vest: Bool
        let vestTex: NSImage
        let gun: NSImage
        let hat: Hat
        let hatColor: NSColor
    }

    private enum Hat { case none, bandana, balaclava, beanie, helmet }

    private static func palette(team: BotTeam, variant: Int) -> Look {
        let v = variant % 4
        if team == .terrorist {
            switch v {
            case 0:
                return Look(
                    skin: MapTextures.skinTone, shirt: MapTextures.camoKhaki, pants: MapTextures.camoSand,
                    boot: MapTextures.bootLeather, vest: true, vestTex: MapTextures.kevlarDark,
                    gun: MapTextures.gunMetal, hat: .balaclava,
                    hatColor: NSColor(calibratedRed: 0.07, green: 0.07, blue: 0.06, alpha: 1)
                )
            case 1:
                return Look(
                    skin: MapTextures.skinTone, shirt: MapTextures.camoOlive, pants: MapTextures.camoSand,
                    boot: MapTextures.bootLeather, vest: false, vestTex: MapTextures.kevlarDark,
                    gun: MapTextures.gunMetal, hat: .none, hatColor: .black
                )
            case 2:
                return Look(
                    skin: MapTextures.skinTone, shirt: MapTextures.camoSand, pants: MapTextures.camoKhaki,
                    boot: MapTextures.bootLeather, vest: true, vestTex: MapTextures.kevlarTan,
                    gun: MapTextures.gunMetal, hat: .beanie,
                    hatColor: NSColor(calibratedRed: 0.12, green: 0.14, blue: 0.10, alpha: 1)
                )
            default:
                return Look(
                    skin: MapTextures.skinTone, shirt: MapTextures.camoOlive, pants: MapTextures.camoKhaki,
                    boot: MapTextures.bootLeather, vest: false, vestTex: MapTextures.kevlarDark,
                    gun: MapTextures.gunMetal, hat: .bandana,
                    hatColor: NSColor(calibratedRed: 0.62, green: 0.12, blue: 0.10, alpha: 1)
                )
            }
        }
        switch v {
        case 1:
            return Look(
                skin: MapTextures.skinTone, shirt: MapTextures.camoCT, pants: MapTextures.camoCTDark,
                boot: MapTextures.bootLeather, vest: true, vestTex: MapTextures.kevlarGreen,
                gun: MapTextures.gunMetal, hat: .beanie,
                hatColor: NSColor(calibratedRed: 0.10, green: 0.16, blue: 0.14, alpha: 1)
            )
        default:
            return Look(
                skin: MapTextures.skinTone, shirt: MapTextures.camoCT, pants: MapTextures.camoCTDark,
                boot: MapTextures.bootLeather, vest: true, vestTex: MapTextures.kevlarGreen,
                gun: MapTextures.gunMetal, hat: .helmet,
                hatColor: NSColor(calibratedRed: 0.16, green: 0.20, blue: 0.16, alpha: 1)
            )
        }
    }

    private static func leg(_ root: SCNNode, x: Float, pants: NSImage, boot: NSImage) {
        let thigh = capsule(0.09, 0.38, at: SCNVector3(x, 0.72, 0.02), tex: pants)
        thigh.scale = SCNVector3(1, 1, 1.08)
        root.addChildNode(thigh)
        let calf = capsule(0.075, 0.36, at: SCNVector3(x, 0.36, 0.03), tex: pants)
        root.addChildNode(calf)
        let foot = box(0.12, 0.10, 0.26, at: SCNVector3(x, 0.07, 0.06), tex: boot)
        root.addChildNode(foot)
    }

    private static func arm(_ root: SCNNode, side: Float, look: Look) {
        let shoulder = sphere(0.09, at: SCNVector3(side * 0.30, 1.50, 0.04), tex: look.shirt)
        root.addChildNode(shoulder)
        let upper = capsule(0.065, 0.30, at: SCNVector3(side * 0.32, 1.38, -0.12), tex: look.shirt)
        upper.eulerAngles.x = -0.85
        root.addChildNode(upper)
        let lower = capsule(0.055, 0.28, at: SCNVector3(side * 0.24, 1.30, -0.34), tex: look.skin)
        lower.eulerAngles.x = -0.35
        root.addChildNode(lower)
        let hand = sphere(0.055, at: SCNVector3(side * 0.18, 1.26, -0.48), tex: look.skin)
        root.addChildNode(hand)
    }

    private static func pouch(_ root: SCNNode, x: Float, tex: NSImage) {
        root.addChildNode(box(0.10, 0.12, 0.08, at: SCNVector3(x, 1.18, 0.18), tex: tex))
    }

    private static func rifle(_ root: SCNNode, look: Look) {
        let wood = MapTextures.gunWood
        let metal = look.gun
        let stock = box(0.05, 0.08, 0.18, at: SCNVector3(0.14, 1.28, -0.22), tex: wood)
        stock.eulerAngles.x = -0.12
        let receiver = box(0.06, 0.08, 0.22, at: SCNVector3(0.14, 1.30, -0.40), tex: metal)
        receiver.eulerAngles.x = -0.12
        receiver.geometry?.firstMaterial = MapTextures.metalSrc(metal)
        let barrel = cylinder(0.016, 0.36, at: SCNVector3(0.14, 1.32, -0.66), tex: metal)
        barrel.eulerAngles.x = .pi / 2 - 0.12
        let mag = box(0.04, 0.14, 0.06, at: SCNVector3(0.14, 1.20, -0.38), tex: metal)
        mag.eulerAngles.x = 0.18
        let grip = box(0.04, 0.12, 0.05, at: SCNVector3(0.14, 1.20, -0.28), tex: wood)
        root.addChildNode(stock)
        root.addChildNode(receiver)
        root.addChildNode(barrel)
        root.addChildNode(mag)
        root.addChildNode(grip)
    }

    private static func addFace(_ head: SCNNode, skin: NSImage) {
        let eye = NSColor(calibratedRed: 0.08, green: 0.08, blue: 0.07, alpha: 1)
        let white = NSColor(calibratedRed: 0.86, green: 0.84, blue: 0.80, alpha: 1)
        head.addChildNode(box(0.04, 0.022, 0.012, at: SCNVector3(-0.038, 0.02, 0.10), color: white))
        head.addChildNode(box(0.04, 0.022, 0.012, at: SCNVector3(0.038, 0.02, 0.10), color: white))
        head.addChildNode(box(0.022, 0.016, 0.012, at: SCNVector3(-0.038, 0.02, 0.108), color: eye))
        head.addChildNode(box(0.022, 0.016, 0.012, at: SCNVector3(0.038, 0.02, 0.108), color: eye))
        head.addChildNode(box(0.05, 0.03, 0.04, at: SCNVector3(0, -0.02, 0.10), tex: skin))
    }

    private static func addHeadgear(_ head: SCNNode, look: Look) {
        switch look.hat {
        case .none:
            break
        case .bandana:
            head.addChildNode(box(0.22, 0.05, 0.22, at: SCNVector3(0, 0.08, 0.01), color: look.hatColor))
        case .balaclava:
            let mask = SCNSphere(radius: 0.118)
            mask.segmentCount = 14
            mask.firstMaterial = MapTextures.goldSrc(look.hatColor)
            let node = SCNNode(geometry: mask)
            node.position = SCNVector3(0, -0.01, 0.01)
            node.scale = SCNVector3(0.96, 0.92, 1.02)
            head.addChildNode(node)
        case .beanie:
            let cap = SCNSphere(radius: 0.125)
            cap.segmentCount = 12
            cap.firstMaterial = MapTextures.goldSrc(look.hatColor)
            let node = SCNNode(geometry: cap)
            node.position = SCNVector3(0, 0.06, 0)
            node.scale = SCNVector3(1, 0.55, 1)
            head.addChildNode(node)
        case .helmet:
            let pot = SCNSphere(radius: 0.135)
            pot.segmentCount = 16
            pot.firstMaterial = MapTextures.metalSrc(look.hatColor)
            let helm = SCNNode(geometry: pot)
            helm.position = SCNVector3(0, 0.06, 0.01)
            helm.scale = SCNVector3(1.02, 0.62, 1.08)
            head.addChildNode(helm)
            head.addChildNode(box(0.20, 0.035, 0.08, at: SCNVector3(0, 0.0, 0.11), color: look.hatColor))
        }
    }

    private static func capsule(_ r: CGFloat, _ h: CGFloat, at: SCNVector3, tex: NSImage) -> SCNNode {
        let g = SCNCapsule(capRadius: r, height: h)
        g.firstMaterial = MapTextures.goldSrc(tex)
        let n = SCNNode(geometry: g)
        n.position = at
        return n
    }

    private static func cylinder(_ r: CGFloat, _ h: CGFloat, at: SCNVector3, tex: NSImage) -> SCNNode {
        let g = SCNCylinder(radius: r, height: h)
        g.radialSegmentCount = 12
        g.firstMaterial = MapTextures.goldSrc(tex)
        let n = SCNNode(geometry: g)
        n.position = at
        return n
    }

    private static func sphere(_ r: CGFloat, at: SCNVector3, tex: NSImage) -> SCNNode {
        let g = SCNSphere(radius: r)
        g.segmentCount = 12
        g.firstMaterial = MapTextures.goldSrc(tex)
        let n = SCNNode(geometry: g)
        n.position = at
        return n
    }

    private static func box(_ w: CGFloat, _ h: CGFloat, _ l: CGFloat, at: SCNVector3, tex: NSImage) -> SCNNode {
        let g = SCNBox(width: w, height: h, length: l, chamferRadius: 0.012)
        g.firstMaterial = MapTextures.goldSrc(tex)
        let n = SCNNode(geometry: g)
        n.position = at
        return n
    }

    private static func box(_ w: CGFloat, _ h: CGFloat, _ l: CGFloat, at: SCNVector3, color: NSColor) -> SCNNode {
        let g = SCNBox(width: w, height: h, length: l, chamferRadius: 0.01)
        g.firstMaterial = MapTextures.goldSrc(color)
        let n = SCNNode(geometry: g)
        n.position = at
        return n
    }
}
