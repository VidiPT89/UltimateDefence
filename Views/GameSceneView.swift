import SwiftUI
import SceneKit
import AppKit

final class FPSSceneView: SCNView {
    var onKey: ((UInt16, Bool) -> Void)?
    var onLook: ((CGFloat, CGFloat) -> Void)?
    var onFire: ((Bool) -> Void)?
    var onFocus: ((Bool) -> Void)?
    private var tracking = false

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.acceptsMouseMovedEvents = true
        becomeFirstResponder()
    }

    func setPointerLocked(_ locked: Bool) {
        tracking = locked
        if locked {
            NSCursor.hide()
            CGAssociateMouseAndMouseCursorPosition(boolean_t(0))
        } else {
            NSCursor.unhide()
            CGAssociateMouseAndMouseCursorPosition(boolean_t(1))
        }
    }

    override func keyDown(with event: NSEvent) {
        if !event.isARepeat { onKey?(event.keyCode, true) }
    }

    override func keyUp(with event: NSEvent) {
        onKey?(event.keyCode, false)
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        onFocus?(true)
        onFire?(true)
    }

    override func mouseUp(with event: NSEvent) {
        onFire?(false)
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
        view.backgroundColor = NSColor.black
        view.onKey = { code, down in world.handleKey(code, down: down) }
        view.onLook = { dx, dy in world.player.look(dx: dx, dy: dy) }
        view.onFire = { down in world.player.shooting = down }
        view.onFocus = { focused in
            session.capturedMouse = focused
        }
        view.isPlaying = true
        view.loops = true
        return view
    }

    func updateNSView(_ nsView: FPSSceneView, context: Context) {
        nsView.setPointerLocked(session.capturedMouse && session.screen == .playing)
        if session.screen != .playing {
            nsView.setPointerLocked(false)
        }
    }

    static func dismantleNSView(_ nsView: FPSSceneView, coordinator: ()) {
        nsView.setPointerLocked(false)
    }
}
