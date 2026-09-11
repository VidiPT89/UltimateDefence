import SwiftUI
import SceneKit
import AppKit

final class FPSSceneView: SCNView {
    var onKey: ((UInt16, Bool) -> Void)?
    var onLook: ((CGFloat, CGFloat) -> Void)?
    var onFire: ((Bool) -> Void)?
    var onAim: ((Bool) -> Void)?
    var onCycle: ((Int) -> Void)?
    var onFocus: ((Bool) -> Void)?
    var fireArmed = false
    private var tracking = false

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.acceptsMouseMovedEvents = true
        if window == nil {
            setPointerLocked(false)
        } else {
            becomeFirstResponder()
        }
    }

    func setPointerLocked(_ locked: Bool) {
        if locked {
            guard !tracking else { return }
            tracking = true
            NSCursor.hide()
            CGAssociateMouseAndMouseCursorPosition(boolean_t(0))
        } else {
            tracking = false
            PointerLock.release()
        }
    }

    override func keyDown(with event: NSEvent) {
        if !event.isARepeat { onKey?(event.keyCode, true) }
    }

    override func keyUp(with event: NSEvent) {
        onKey?(event.keyCode, false)
    }

    override func flagsChanged(with event: NSEvent) {
        onKey?(56, event.modifierFlags.contains(.shift))
        onKey?(59, event.modifierFlags.contains(.control))
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        onFocus?(true)
        if fireArmed {
            onFire?(true)
        }
    }

    override func mouseUp(with event: NSEvent) {
        onFire?(false)
    }

    override func rightMouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        onFocus?(true)
        onAim?(true)
    }

    override func rightMouseUp(with event: NSEvent) {
        onAim?(false)
    }

    override func scrollWheel(with event: NSEvent) {
        if event.scrollingDeltaY > 0.4 {
            onCycle?(-1)
        } else if event.scrollingDeltaY < -0.4 {
            onCycle?(1)
        }
    }

    override func mouseMoved(with event: NSEvent) {
        guard tracking else { return }
        onLook?(event.deltaX, event.deltaY)
    }

    override func mouseDragged(with event: NSEvent) {
        guard tracking else { return }
        onLook?(event.deltaX, event.deltaY)
    }
}

struct GameSceneView: NSViewRepresentable {
    let world: GameWorld
    @ObservedObject var session: GameSession

    func makeNSView(context: Context) -> FPSSceneView {
        let view = FPSSceneView()
        view.scene = world.scene
        view.delegate = world
        view.pointOfView = world.player.cameraNode
        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = false
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 60
        view.isJitteringEnabled = true
        view.backgroundColor = NSColor(calibratedRed: 0.58, green: 0.73, blue: 0.88, alpha: 1)
        view.onKey = { code, down in world.handleKey(code, down: down) }
        view.onLook = { dx, dy in world.player.look(dx: dx, dy: dy) }
        view.onFire = { down in world.player.shooting = down }
        view.onAim = { down in world.player.aiming = down }
        view.onCycle = { dir in world.cycleWeapon(dir) }
        view.onFocus = { focused in
            DispatchQueue.main.async {
                if session.screen == .playing {
                    session.capturedMouse = focused
                }
            }
        }
        view.isPlaying = true
        view.loops = true
        return view
    }

    func updateNSView(_ nsView: FPSSceneView, context: Context) {
        nsView.scene = world.scene
        nsView.delegate = world
        nsView.pointOfView = world.player.cameraNode
        nsView.onKey = { code, down in world.handleKey(code, down: down) }
        nsView.onLook = { dx, dy in world.player.look(dx: dx, dy: dy) }
        nsView.onFire = { down in world.player.shooting = down }
        nsView.onAim = { down in world.player.aiming = down }
        nsView.onCycle = { dir in world.cycleWeapon(dir) }
        nsView.window?.acceptsMouseMovedEvents = true
        if session.screen == .playing {
            nsView.window?.makeFirstResponder(nsView)
            nsView.setPointerLocked(session.capturedMouse)
            nsView.fireArmed = session.capturedMouse
        } else {
            nsView.setPointerLocked(false)
            nsView.fireArmed = false
        }
    }

    static func dismantleNSView(_ nsView: FPSSceneView, coordinator: ()) {
        nsView.setPointerLocked(false)
    }
}

enum PointerLock {
    static func release() {
        NSCursor.unhide()
        CGAssociateMouseAndMouseCursorPosition(boolean_t(1))
        CGDisplayShowCursor(CGMainDisplayID())
    }
}
