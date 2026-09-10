import SceneKit
import AppKit

enum CharacterMesh {
    static func attach(to root: SCNNode, team: BotTeam, variant: Int, name: String, headName: String) -> SCNNode {
        let look = palette(team: team, variant: variant)
        let hips = box(0.34, 0.18, 0.2, at: SCNVector3(0, 0.98, 0), color: look.pants)
        root.addChildNode(hips)

        thigh(root, x: -0.11, color: look.pants)
        thigh(root, x: 0.11, color: look.pants)
        calf(root, x: -0.11, color: look.pants)
        calf(root, x: 0.11, color: look.pants)
        root.addChildNode(box(0.14, 0.12, 0.28, at: SCNVector3(-0.11, 0.08, 0.04), color: look.boot))
        root.addChildNode(box(0.14, 0.12, 0.28, at: SCNVector3(0.11, 0.08, 0.04), color: look.boot))

        let chest = box(0.42, 0.48, 0.26, at: SCNVector3(0, 1.32, 0), color: look.shirt)
        chest.name = name
        root.addChildNode(chest)
        if look.vest {
            root.addChildNode(box(0.44, 0.28, 0.3, at: SCNVector3(0, 1.28, 0.02), color: look.vestColor))
        }

        let headGeom = SCNBox(width: 0.2, height: 0.24, length: 0.22, chamferRadius: 0.02)
        headGeom.firstMaterial = MapTextures.goldSrc(look.skin)
        let head = SCNNode(geometry: headGeom)
        head.name = headName
        head.position = SCNVector3(0, 1.68, 0.02)
        root.addChildNode(head)
        root.addChildNode(box(0.12, 0.1, 0.12, at: SCNVector3(0, 1.54, 0.02), color: look.skin))
        addHeadgear(head, look: look)
        let eye = NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.1, alpha: 1)
        head.addChildNode(box(0.035, 0.03, 0.02, at: SCNVector3(-0.045, 0.02, 0.11), color: eye))
        head.addChildNode(box(0.035, 0.03, 0.02, at: SCNVector3(0.045, 0.02, 0.11), color: eye))

        arm(root, side: -1, look: look)
        arm(root, side: 1, look: look)
        if team == .terrorist {
            root.addChildNode(box(0.22, 0.28, 0.16, at: SCNVector3(-0.02, 1.3, 0.18), color: look.vestColor))
        }
        let gun = box(0.06, 0.08, 0.42, at: SCNVector3(0.12, 1.38, -0.42), color: look.gun)
        gun.eulerAngles.x = -0.08
        root.addChildNode(gun)
        return head
    }

    private struct Look {
        let skin: NSColor
        let shirt: NSColor
        let pants: NSColor
        let boot: NSColor
        let vest: Bool
        let vestColor: NSColor
        let gun: NSColor
        let hat: Hat
    }

    private enum Hat { case none, bandana, balaclava, beanie, helmet }

    private static func palette(team: BotTeam, variant: Int) -> Look {
        let skin = NSColor(calibratedRed: 0.76, green: 0.58, blue: 0.45, alpha: 1)
        let boot = NSColor(calibratedRed: 0.08, green: 0.07, blue: 0.06, alpha: 1)
        let gun = NSColor(calibratedRed: 0.14, green: 0.15, blue: 0.14, alpha: 1)
        let v = variant % 4
        if team == .terrorist {
            switch v {
            case 0:
                return Look(skin: skin,
                            shirt: NSColor(calibratedRed: 0.22, green: 0.24, blue: 0.2, alpha: 1),
                            pants: NSColor(calibratedRed: 0.72, green: 0.64, blue: 0.42, alpha: 1),
                            boot: boot, vest: true,
                            vestColor: NSColor(calibratedRed: 0.18, green: 0.18, blue: 0.16, alpha: 1),
                            gun: gun, hat: .balaclava)
            case 1:
                return Look(skin: skin,
                            shirt: NSColor(calibratedRed: 0.28, green: 0.38, blue: 0.22, alpha: 1),
                            pants: NSColor(calibratedRed: 0.7, green: 0.62, blue: 0.4, alpha: 1),
                            boot: boot, vest: false,
                            vestColor: boot, gun: gun, hat: .none)
            case 2:
                return Look(skin: skin,
                            shirt: NSColor(calibratedRed: 0.55, green: 0.52, blue: 0.42, alpha: 1),
                            pants: NSColor(calibratedRed: 0.45, green: 0.42, blue: 0.32, alpha: 1),
                            boot: boot, vest: true,
                            vestColor: NSColor(calibratedRed: 0.62, green: 0.58, blue: 0.48, alpha: 1),
                            gun: gun, hat: .beanie)
            default:
                return Look(skin: skin,
                            shirt: NSColor(calibratedRed: 0.32, green: 0.28, blue: 0.2, alpha: 1),
                            pants: NSColor(calibratedRed: 0.42, green: 0.38, blue: 0.22, alpha: 1),
                            boot: boot, vest: false,
                            vestColor: boot, gun: gun, hat: .bandana)
            }
        }
        switch v {
        case 0:
            return Look(skin: skin,
                        shirt: NSColor(calibratedRed: 0.12, green: 0.16, blue: 0.14, alpha: 1),
                        pants: NSColor(calibratedRed: 0.1, green: 0.12, blue: 0.1, alpha: 1),
                        boot: boot, vest: true,
                        vestColor: NSColor(calibratedRed: 0.14, green: 0.18, blue: 0.16, alpha: 1),
                        gun: gun, hat: .helmet)
        case 1:
            return Look(skin: skin,
                        shirt: NSColor(calibratedRed: 0.18, green: 0.2, blue: 0.22, alpha: 1),
                        pants: NSColor(calibratedRed: 0.16, green: 0.16, blue: 0.18, alpha: 1),
                        boot: boot, vest: true,
                        vestColor: NSColor(calibratedRed: 0.2, green: 0.22, blue: 0.18, alpha: 1),
                        gun: gun, hat: .beanie)
        case 2:
            return Look(skin: skin,
                        shirt: NSColor(calibratedRed: 0.14, green: 0.16, blue: 0.2, alpha: 1),
                        pants: NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.14, alpha: 1),
                        boot: boot, vest: true,
                        vestColor: NSColor(calibratedRed: 0.16, green: 0.18, blue: 0.2, alpha: 1),
                        gun: gun, hat: .helmet)
        default:
            return Look(skin: skin,
                        shirt: NSColor(calibratedRed: 0.16, green: 0.18, blue: 0.22, alpha: 1),
                        pants: NSColor(calibratedRed: 0.12, green: 0.13, blue: 0.16, alpha: 1),
                        boot: boot, vest: true,
                        vestColor: NSColor(calibratedRed: 0.1, green: 0.12, blue: 0.16, alpha: 1),
                        gun: gun, hat: .balaclava)
        }
    }

    private static func thigh(_ root: SCNNode, x: Float, color: NSColor) {
        root.addChildNode(box(0.13, 0.36, 0.16, at: SCNVector3(x, 0.72, 0.01), color: color))
    }

    private static func calf(_ root: SCNNode, x: Float, color: NSColor) {
        root.addChildNode(box(0.12, 0.34, 0.15, at: SCNVector3(x, 0.38, 0.02), color: color))
    }

    private static func arm(_ root: SCNNode, side: Float, look: Look) {
        let shoulder = box(0.12, 0.14, 0.14, at: SCNVector3(side * 0.28, 1.46, 0.02), color: look.shirt)
        root.addChildNode(shoulder)
        let upper = box(0.11, 0.12, 0.28, at: SCNVector3(side * 0.3, 1.4, -0.16), color: look.shirt)
        upper.eulerAngles.x = -0.55
        root.addChildNode(upper)
        let lower = box(0.1, 0.1, 0.26, at: SCNVector3(side * 0.22, 1.36, -0.38), color: look.skin)
        lower.eulerAngles.x = -0.2
        root.addChildNode(lower)
        root.addChildNode(box(0.09, 0.08, 0.1, at: SCNVector3(side * 0.16, 1.34, -0.52), color: look.skin))
    }

    private static func addHeadgear(_ head: SCNNode, look: Look) {
        switch look.hat {
        case .none:
            break
        case .bandana:
            head.addChildNode(box(0.22, 0.06, 0.24, at: SCNVector3(0, 0.08, 0.01), color: NSColor(calibratedRed: 0.7, green: 0.18, blue: 0.12, alpha: 1)))
        case .balaclava:
            head.addChildNode(box(0.21, 0.2, 0.23, at: SCNVector3(0, 0.02, 0), color: NSColor(calibratedRed: 0.08, green: 0.08, blue: 0.08, alpha: 1)))
        case .beanie:
            head.addChildNode(box(0.22, 0.1, 0.24, at: SCNVector3(0, 0.14, 0), color: NSColor(calibratedRed: 0.12, green: 0.14, blue: 0.12, alpha: 1)))
        case .helmet:
            head.addChildNode(box(0.24, 0.12, 0.26, at: SCNVector3(0, 0.14, 0.01), color: NSColor(calibratedRed: 0.14, green: 0.16, blue: 0.14, alpha: 1)))
        }
    }

    private static func box(_ w: CGFloat, _ h: CGFloat, _ l: CGFloat, at: SCNVector3, color: NSColor) -> SCNNode {
        let g = SCNBox(width: w, height: h, length: l, chamferRadius: 0.028)
        g.firstMaterial = MapTextures.goldSrc(color)
        let n = SCNNode(geometry: g)
        n.position = at
        return n
    }
}
