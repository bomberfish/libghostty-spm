#if os(macOS) && canImport(AppKit) && !canImport(UIKit)
    @testable import GhosttyTerminal
    import Testing

    @MainActor
    struct TerminalCommandFinishedTests {
        @Test
        func `every command completion advances the sequence`() async {
            let state = TerminalViewState()

            state.terminalDidFinishCommand(exitCode: 0, durationNanos: 1)
            await Task.yield()
            #expect(state.commandFinishedSequence == 1)

            state.terminalDidFinishCommand(exitCode: 0, durationNanos: 1)
            await Task.yield()
            #expect(state.commandFinishedSequence == 2)
        }
    }
#endif
