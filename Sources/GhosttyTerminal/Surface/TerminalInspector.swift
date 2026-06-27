//
//  TerminalInspector.swift
//  libghostty-spm
//
//  Swift wrapper around `ghostty_inspector_t` — the ImGui-based terminal
//  inspector (VT stream, keyboard, cell, and renderer debugging UI).
//
//  Reference:
//  - ghostty-org/ghostty
//  - macos/Sources/Ghostty/Ghostty.Inspector.swift
//

import GhosttyKit

#if canImport(Metal)
    import Metal
#endif

/// Mouse buttons understood by the inspector.
public enum TerminalMouseButton: Sendable, Hashable {
    case left
    case right
    case middle

    var ghosttyValue: ghostty_input_mouse_button_e {
        switch self {
        case .left: GHOSTTY_MOUSE_LEFT
        case .right: GHOSTTY_MOUSE_RIGHT
        case .middle: GHOSTTY_MOUSE_MIDDLE
        }
    }
}

/// Thread-safe wrapper around `ghostty_inspector_t`.
///
/// An inspector is owned by its ``TerminalSurface`` and shares the surface's
/// lifetime: it is freed when the surface is freed. All methods are no-ops
/// once the owning surface has been freed, so it is safe to hold a reference
/// past surface teardown.
///
/// The inspector renders through a host-provided Metal layer (unlike the
/// surface, which Ghostty renders into directly). Use ``TerminalInspectorView``
/// for a ready-made SwiftUI renderer, or drive ``metalInit(device:)`` /
/// ``metalRender(commandBuffer:descriptor:)`` yourself.
@MainActor
public final class TerminalInspector {
    private let handle: ghostty_inspector_t
    private weak var owner: TerminalSurface?

    init(handle: ghostty_inspector_t, owner: TerminalSurface) {
        self.handle = handle
        self.owner = owner
    }

    /// Whether the owning surface is still alive. Once `false`, every method
    /// on this inspector is a no-op.
    public var isValid: Bool {
        owner?.rawValue != nil
    }

    private var validHandle: ghostty_inspector_t? {
        isValid ? handle : nil
    }

    // MARK: - State

    public func setFocus(_ focused: Bool) {
        guard let h = validHandle else { return }
        TerminalDebugLog.log(.lifecycle, "inspector focus=\(focused)")
        ghostty_inspector_set_focus(h, focused)
    }

    public func setContentScale(x: Double, y: Double) {
        guard let h = validHandle else { return }
        ghostty_inspector_set_content_scale(h, x, y)
    }

    public func setSize(width: UInt32, height: UInt32) {
        guard let h = validHandle else { return }
        ghostty_inspector_set_size(h, width, height)
    }

    // MARK: - Input

    public func mousePosition(x: Double, y: Double) {
        guard let h = validHandle else { return }
        ghostty_inspector_mouse_pos(h, x, y)
    }

    public func mouseButton(
        _ pressed: Bool,
        button: TerminalMouseButton = .left,
        mods: TerminalInputModifiers = []
    ) {
        guard let h = validHandle else { return }
        ghostty_inspector_mouse_button(
            h,
            pressed ? GHOSTTY_MOUSE_PRESS : GHOSTTY_MOUSE_RELEASE,
            button.ghosttyValue,
            mods.ghosttyMods
        )
    }

    public func mouseScroll(x: Double, y: Double, mods: TerminalScrollModifiers = .init()) {
        guard let h = validHandle else { return }
        ghostty_inspector_mouse_scroll(h, x, y, mods.rawValue)
    }

    /// Sends committed text (used by ImGui text fields).
    public func sendText(_ text: String) {
        guard let h = validHandle else { return }
        text.withCString { ghostty_inspector_text(h, $0) }
    }

    /// Sends a raw key event. Exposed at the ghostty layer because the
    /// inspector keys on the translated key enum rather than a keycode.
    func sendKey(
        action: ghostty_input_action_e,
        key: ghostty_input_key_e,
        mods: ghostty_input_mods_e
    ) {
        guard let h = validHandle else { return }
        ghostty_inspector_key(h, action, key, mods)
    }

    // MARK: - Metal Rendering (Apple)

    #if canImport(Metal)
        /// Initializes the inspector's Metal backend with the given device.
        ///
        /// Ghostty takes ownership of the passed device reference (it releases
        /// it after binding), so this mirrors the upstream `passRetained`
        /// ownership contract.
        @discardableResult
        public func metalInit(device: MTLDevice) -> Bool {
            guard let h = validHandle else { return false }
            return ghostty_inspector_metal_init(
                h,
                Unmanaged.passRetained(device).toOpaque()
            )
        }

        /// Encodes the inspector UI into `commandBuffer` using `descriptor`.
        ///
        /// Ghostty releases both the command buffer and descriptor when it is
        /// done with them, matching the upstream `passRetained` contract — do
        /// not balance these yourself.
        public func metalRender(
            commandBuffer: MTLCommandBuffer,
            descriptor: MTLRenderPassDescriptor
        ) {
            guard let h = validHandle else { return }
            ghostty_inspector_metal_render(
                h,
                Unmanaged.passRetained(commandBuffer).toOpaque(),
                Unmanaged.passRetained(descriptor).toOpaque()
            )
        }

        /// Tears down the inspector's Metal backend.
        @discardableResult
        public func metalShutdown() -> Bool {
            guard let h = validHandle else { return false }
            return ghostty_inspector_metal_shutdown(h)
        }
    #endif
}
