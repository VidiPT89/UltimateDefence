import SceneKit
import QuartzCore
import simd

final class PlayerController {
    let node = SCNNode()
    let cameraNode = SCNNode()
    var yaw: Float = .pi * 0.85
    var pitch: Float = 0
    var keys = Set<UInt16>()
    var shooting = false
    var health = GameRules.playerMaxHealth
    var slot: WeaponSlot = .rifle
    var mag: [WeaponSlot: Int] = [.rifle: WeaponStats.rifle.magazine, .pistol: WeaponStats.pistol.magazine]
    var reserve: [WeaponSlot: Int] = [.rifle: WeaponStats.rifle.reserve, .pistol: WeaponStats.pistol.reserve]
    var lastShot: TimeInterval = -10
    var reloadingUntil: TimeInterval = 0
    var defuseProgress: TimeInterval = 0
    var interacting = false
    var bob: Float = 0
    var moving = false
    private var lastSlot: WeaponSlot?

    var isAlive: Bool { health > 0 }
    var currentStats: WeaponStats { slot.stats }
    var currentMag: Int { mag[slot] ?? 0 }

    func setup(at spawn: SIMD3<Float>) {
        node.name = NodeName.player
        node.position = SCNVector3(spawn.x, spawn.y, spawn.z)
        cameraNode.name = NodeName.camera
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 68
        cameraNode.camera?.zFar = 140
        cameraNode.camera?.wantsHDR = true
        cameraNode.camera?.bloomIntensity = 0.35
        cameraNode.camera?.motionBlurIntensity = 0.15
        cameraNode.position = SCNVector3Zero
        if cameraNode.parent !== node {
            node.addChildNode(cameraNode)
        }
        WeaponRig.attach(to: cameraNode, slot: slot)
        lastSlot = slot
        applyLook()
    }

    func applyLook() {
        pitch = min(1.25, max(-1.25, pitch))
        node.eulerAngles.y = CGFloat(yaw)
        cameraNode.eulerAngles.x = CGFloat(pitch)
    }

    func look(dx: CGFloat, dy: CGFloat, sensitivity: Float = 0.0045) {
        yaw -= Float(dx) * sensitivity
        pitch -= Float(dy) * sensitivity
        applyLook()
    }

    func forward() -> SIMD3<Float> {
        SIMD3(-sin(yaw), 0, -cos(yaw))
    }

    func right() -> SIMD3<Float> {
        SIMD3(cos(yaw), 0, -sin(yaw))
    }

    func move(dt: Float, walls: [AABB]) {
        guard isAlive else { return }
        var dir = SIMD3<Float>(repeating: 0)
        if keys.contains(13) || keys.contains(126) { dir += forward() } // W / up
        if keys.contains(1) || keys.contains(125) { dir -= forward() } // S
        if keys.contains(0) || keys.contains(123) { dir -= right() } // A
        if keys.contains(2) || keys.contains(124) { dir += right() } // D
        let length = simd_length(dir)
        moving = length > 0.001
        if !moving {
            bob = max(0, bob - dt * 6)
            cameraNode.position.y = CGFloat(sin(bob) * 0.01)
            return
        }
        dir /= length
        bob += dt * 11
        cameraNode.position = SCNVector3(sin(bob) * 0.018, sin(bob * 2) * 0.045, 0)
        let proposed = SIMD3(Float(node.position.x), Float(node.position.y), Float(node.position.z)) + dir * GameRules.playerSpeed * dt
        let resolved = Collision.resolve(
            position: SIMD3(Float(node.position.x), Float(node.position.y), Float(node.position.z)),
            proposed: proposed,
            radius: 0.55,
            walls: walls
        )
        node.position = SCNVector3(resolved.x, resolved.y, resolved.z)
    }

    func selectSlot(_ newSlot: WeaponSlot) {
        guard reloadingUntil <= CACurrentMediaTime() else { return }
        slot = newSlot
        if lastSlot != newSlot {
            WeaponRig.attach(to: cameraNode, slot: newSlot)
            lastSlot = newSlot
        }
    }

    func startReload(now: TimeInterval) {
        let stats = currentStats
        let current = mag[slot] ?? 0
        let stored = reserve[slot] ?? 0
        guard current < stats.magazine, stored > 0, now >= reloadingUntil else { return }
        reloadingUntil = now + stats.reloadTime
    }

    func finishReloadIfNeeded(now: TimeInterval) {
        guard now >= reloadingUntil, reloadingUntil > 0 else { return }
        let stats = currentStats
        let current = mag[slot] ?? 0
        var stored = reserve[slot] ?? 0
        let need = stats.magazine - current
        let take = min(need, stored)
        mag[slot] = current + take
        stored -= take
        reserve[slot] = stored
        reloadingUntil = 0
    }

    func canShoot(now: TimeInterval) -> Bool {
        isAlive
            && shooting
            && now >= reloadingUntil
            && now - lastShot >= currentStats.fireInterval
            && (mag[slot] ?? 0) > 0
    }

    func consumeShot(now: TimeInterval) {
        mag[slot] = max(0, (mag[slot] ?? 0) - 1)
        lastShot = now
        if mag[slot] == 0 {
            startReload(now: now)
        }
    }

    func takeDamage(_ amount: Int) {
        health = GameRules.remainingHealth(current: health, damage: amount)
    }

    var worldPosition: SIMD3<Float> {
        SIMD3(Float(node.position.x), Float(node.position.y), Float(node.position.z))
    }
}
