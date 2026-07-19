#if os(macOS) && canImport(AppKit) && !canImport(UIKit)
    @testable import GhosttyTerminal
    import Testing

    @MainActor
    struct TerminalAppKitProcessLifecycleAPITests {
        @Test
        func `unattached state has safe lifecycle defaults`() {
            let state = TerminalViewState()

            #expect(state.foregroundPid == nil)
            #expect(state.ttyName == nil)
            #expect(!state.needsConfirmQuit)
            #expect(state.processExited)
            #expect(!state.requestClose())
        }
    }
#endif
