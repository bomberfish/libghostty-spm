@testable import GhosttyTerminal
import GhosttyKit
import Testing

@MainActor
struct TerminalLifecycleTests {
    /// A live surface wrapper must keep its controller (and therefore the
    /// Ghostty app that owns the surface's memory) alive. `ghostty_app_free`
    /// in `TerminalController.deinit` frees every surface without nilling any
    /// wrapper's `rawValue`, so if the app could outlive-race the wrapper a
    /// snapshot read like `readLatestPromptVT()` would dereference a freed
    /// renderer mutex and crash. The bogus handle is never dereferenced: the
    /// test performs no reads and never calls `free()`, and `deinit` does not
    /// touch the surface.
    @Test
    func `surface wrapper pins its controller alive until freed`() {
        weak var weakController: TerminalController?
        var surface: TerminalSurface?

        do {
            let controller = TerminalController()
            weakController = controller
            let handle = ghostty_surface_t(bitPattern: 0x1)!
            surface = TerminalSurface(handle, controller: controller)
        }

        // The wrapper is now the only owner of the controller.
        #expect(weakController != nil)

        surface = nil
        _ = surface
        #expect(weakController == nil)
    }

    @Test
    func `failed surface creation does not retain bridge`() {
        let controller = TerminalController()
        let bridge = TerminalCallbackBridge()

        let surface = controller.createSurface(
            bridge: bridge,
            configuration: .init()
        ) { _ in }

        #expect(surface == nil)
        #expect(controller.retainedBridgeCount == 0)
    }

    @Test
    func `switching controllers removes bridge from old controller`() {
        let oldController = TerminalController()
        let newController = TerminalController()
        let coordinator = TerminalSurfaceCoordinator()

        coordinator.isAttached = { false }
        oldController.retain(coordinator.bridge)
        #expect(oldController.retainedBridgeCount == 1)

        coordinator.controller = oldController
        #expect(oldController.retainedBridgeCount == 0)

        oldController.retain(coordinator.bridge)
        #expect(oldController.retainedBridgeCount == 1)

        coordinator.controller = newController

        #expect(oldController.retainedBridgeCount == 0)
        #expect(newController.retainedBridgeCount == 0)
    }

    @Test
    func `free surface removes retained bridge`() {
        let controller = TerminalController()
        let coordinator = TerminalSurfaceCoordinator()

        coordinator.isAttached = { false }
        coordinator.controller = controller

        controller.retain(coordinator.bridge)
        #expect(controller.retainedBridgeCount == 1)

        coordinator.freeSurface()

        #expect(controller.retainedBridgeCount == 0)
    }

    @Test
    func `suspended wakeup does not schedule render`() {
        let controller = TerminalController()
        var wakeups = 0

        controller.shouldProcessWakeup = { false }
        controller.onWakeup = {
            wakeups += 1
        }

        controller.handleWakeup()

        #expect(wakeups == 0)
    }

    @Test
    func `application active state controls immediate ticks`() async {
        let coordinator = TerminalSurfaceCoordinator()
        var renders = 0

        coordinator.isAttached = { true }
        coordinator.onPostRender = {
            renders += 1
        }

        coordinator.setApplicationActive(false)
        coordinator.requestImmediateTick()
        await Task.yield()

        #expect(renders == 0)

        coordinator.setApplicationActive(true)
        await Task.yield()

        #expect(renders == 1)
    }
}
