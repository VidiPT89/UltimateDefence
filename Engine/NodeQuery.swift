import SceneKit
import simd

enum NodeQuery {
    static func hitDistance(_ hit: SCNHitTestResult, from: SIMD3<Float>) -> Float {
        let p = hit.worldCoordinates
        return hypot(hypot(Float(p.x) - from.x, Float(p.y) - from.y), Float(p.z) - from.z)
    }

    static func isTrim(_ node: SCNNode) -> Bool {
        named(node, NodeName.trim)
    }

    static func isSolidCover(_ node: SCNNode) -> Bool {
        named(node, NodeName.solid) || named(node, NodeName.ground)
    }

    static func isPlayerGeometry(_ node: SCNNode) -> Bool {
        var current: SCNNode? = node
        while let node = current {
            let name = node.name ?? ""
            if name == NodeName.player || name == NodeName.camera || name == "weaponRig" {
                return true
            }
            current = node.parent
        }
        return false
    }

    private static func named(_ node: SCNNode, _ value: String) -> Bool {
        var current: SCNNode? = node
        while let node = current {
            if node.name == value { return true }
            current = node.parent
        }
        return false
    }
}
