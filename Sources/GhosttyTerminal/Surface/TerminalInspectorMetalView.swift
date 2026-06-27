//
//  TerminalInspectorMetalView.swift
//  libghostty-spm
//
//  A Metal-backed view that renders a surface's terminal inspector and
//  forwards pointer / keyboard input to it. Cross-platform via MetalKit's
//  MTKView (UIView on iOS, NSView on macOS / Catalyst).
//
//  Reference:
//  - ghostty-org/ghostty
//  - macos/Sources/Ghostty/Surface View/InspectorView.swift
//

import GhosttyKit
import MetalKit

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

/// Renders the ImGui terminal inspector for a ``TerminalViewState``'s surface.
///
/// The view resolves the inspector lazily from the state's surface, so it can
/// be created before the surface is attached. Once the surface goes away the
/// view stops rendering automatically.
@MainActor
final class TerminalInspectorMetalView: MTKView {
    /// The state whose surface the inspector belongs to.
    weak var viewState: TerminalViewState? {
        didSet {
            guard viewState !== oldValue else { return }
            resolvedInspector = nil
        }
    }

    private var commandQueue: MTLCommandQueue?
    private var resolvedInspector: TerminalInspector?

    init(frame: CGRect) {
        let device = MTLCreateSystemDefaultDevice()
        commandQueue = device?.makeCommandQueue()
        super.init(frame: frame, device: device)

        // Timed render mode — required so the inspector animates and reflects
        // live VT activity even without explicit invalidation.
        isPaused = false
        enableSetNeedsDisplay = false
        preferredFramesPerSecond = 30
        framebufferOnly = true

        // Match upstream's inspector background.
        clearColor = MTLClearColor(
            red: 0x28 / 0xFF,
            green: 0x2C / 0xFF,
            blue: 0x34 / 0xFF,
            alpha: 1
        )

        #if canImport(UIKit)
            isOpaque = true
            isMultipleTouchEnabled = false
        #endif
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Inspector Resolution

    private func resolveInspector() -> TerminalInspector? {
        if let resolvedInspector, resolvedInspector.isValid {
            return resolvedInspector
        }
        resolvedInspector = nil

        guard let inspector = viewState?.surface?.inspector() else {
            return nil
        }
        resolvedInspector = inspector

        #if canImport(Metal)
            if let device {
                inspector.metalInit(device: device)
            }
        #endif
        updateSize(inspector)
        return inspector
    }

    private func updateSize(_ inspector: TerminalInspector) {
        let bounds = bounds
        guard bounds.width > 0, bounds.height > 0 else { return }

        // drawableSize is in pixels; bounds in points. Their ratio is the
        // content (backing) scale.
        let drawable = drawableSize
        guard drawable.width > 0, drawable.height > 0 else { return }

        let scaleX = drawable.width / bounds.width
        let scaleY = drawable.height / bounds.height
        inspector.setContentScale(x: Double(scaleX), y: Double(scaleY))
        inspector.setSize(
            width: UInt32(drawable.width),
            height: UInt32(drawable.height)
        )
    }

    // MARK: - Rendering

    override func draw(_ rect: CGRect) {
        guard let inspector = resolveInspector() else { return }

        // Always refresh size: draw can occur between resize callbacks and a
        // stale size relative to the drawable will crash the renderer.
        updateSize(inspector)

        guard
            let commandQueue,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let descriptor = currentRenderPassDescriptor
        else { return }

        inspector.metalRender(commandBuffer: commandBuffer, descriptor: descriptor)

        if let drawable = currentDrawable {
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()
    }

    // MARK: - Focus / Lifecycle

    func setInspectorFocus(_ focused: Bool) {
        resolveInspector()?.setFocus(focused)
    }
}
