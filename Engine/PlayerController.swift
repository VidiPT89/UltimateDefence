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
    var sprinting = false
    var grounded = true
    var vertical: Float = 0
    var aiming = false
    var walking = false
    var crouching = false
    var punch: Float = 0
    var roundStart: TimeInterval = 0
    var velocity = SIMD3<Float>(repeating: 0)
    private var lastSlot: WeaponSlot?

    var isAlive: Bool { health > 0 }
    var currentStats: WeaponStats { slot.stats }
    var currentMag: Int { mag[slot] ?? 0 }

    func setup(at spawn: SIMD3<Float>) {
        node.name = NodeName.player
        node.position = SCNVector3(spawn.x, spawn.y, spawn.z)
        cameraNode.name = NodeName.camera
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 88
        cameraNode.camera?.zNear = 0.12
        cameraNode.camera?.zFar = 220
        cameraNode.camera?.wantsHDR = false
        cameraNode.camera?.bloomIntensity = 0
        cameraNode.camera?.motionBlurIntensity = 0
        cameraNode.camera?.vignettingIntensity = 0
        cameraNode.camera?.screenSpaceAmbientOcclusionIntensity = 0
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
        cameraNode.eulerAngles.x = CGFloat(pitch + punch)
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
        crouching = keys.contains(59)
        walking = keys.contains(56) && moving && !crouching
        sprinting = moving && !walking && !crouching && !aiming
        let standEye: Float = 1.64
        let crouchEye: Float = 1.18
        let targetFOV: CGFloat = aiming ? 62 : 88
        if let cam = cameraNode.camera {
            cam.fieldOfView += (targetFOV - cam.fieldOfView) * CGFloat(min(1, dt * 10))
        }
        if keys.contains(49), grounded {
            vertical = GameRules.jumpVelocity
            grounded = false
        }
        vertical -= GameRules.gravity * dt
        var y = Float(node.position.y) + vertical * dt
        punch = max(0, punch - dt * 2.4)
        let eye = crouching ? crouchEye : standEye
        if y <= eye + 0.06 {
            if eye - y < 0.58 || grounded {
                y = eye
                vertical = 0
                grounded = true
            }
        } else {
            grounded = false
        }

        if !moving {
            velocity *= max(0, 1 - dt * 10)
            bob = max(0, bob - dt * 6)
            cameraNode.position.y = CGFloat(sin(bob) * 0.014)
            node.position.y = CGFloat(y)
            return
        }
        dir /= length
        var speed = GameRules.playerSpeed
        if walking { speed *= GameRules.walkMultiplier }
        if crouching { speed *= GameRules.crouchMultiplier }
        if aiming { speed *= 0.78 }
        if shooting { speed *= GameRules.shootSpeedMultiplier }
        let target = dir * speed
        velocity += (target - velocity) * min(1, dt * 11)
        bob += dt * (walking ? 7 : crouching ? 6 : 12)
        cameraNode.position = SCNVector3(sin(bob) * 0.018, sin(bob * 2) * 0.038, 0)
        let proposed = SIMD3(Float(node.position.x), y, Float(node.position.z)) + velocity * dt
        let resolved = Collision.resolve(
            position: SIMD3(Float(node.position.x), y, Float(node.position.z)),
            proposed: proposed,
            radius: 0.42,
            walls: walls
        )
        if hypot(resolved.x - proposed.x, resolved.z - proposed.z) > 0.01 {
            velocity = SIMD3(resolved.x - Float(node.position.x), 0, resolved.z - Float(node.position.z)) / max(dt, 0.001)
        }
        let landed = eye
        if y <= landed + 0.06, landed - y < 0.58 || grounded {
            y = landed
            vertical = 0
            grounded = true
        }
        node.position = SCNVector3(resolved.x, y, resolved.z)
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
            && now - roundStart >= 0.25
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
