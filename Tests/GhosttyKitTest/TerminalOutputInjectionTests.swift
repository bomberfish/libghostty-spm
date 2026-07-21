#if os(macOS) && canImport(AppKit) && !canImport(UIKit)
    @testable import GhosttyTerminal
    import Testing

    @MainActor
    struct TerminalOutputInjectionTests {
        @Test
        func `unattached state rejects output injection`() {
            let state = TerminalViewState()

            #expect(!state.injectTerminalOutput("\u{1B}[999B"))
        }
    }
#endif
