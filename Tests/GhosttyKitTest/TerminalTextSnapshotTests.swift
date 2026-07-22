#if os(macOS) && canImport(AppKit) && !canImport(UIKit)
    @testable import GhosttyTerminal
    import Testing

    @MainActor
    struct TerminalTextSnapshotTests {
        @Test
        func `unattached state has no screen snapshot`() {
            let state = TerminalViewState()

            #expect(state.readScreenText() == nil)
            #expect(state.readViewportText() == nil)
            #expect(state.readLatestPromptVT() == nil)
        }
    }
#endif
