#if os(macOS) && canImport(AppKit) && !canImport(UIKit)
    @testable import GhosttyTerminal
    import Testing

    @MainActor
    struct TerminalProgressReportTests {
        @Test
        func `view state records and removes progress reports`() async {
            let state = TerminalViewState()

            state.terminalDidReportProgress(state: .set, percent: 42)
            await Task.yield()
            #expect(state.progressReport == .init(state: .set, percent: 42))

            state.terminalDidReportProgress(state: .remove, percent: nil)
            await Task.yield()
            #expect(state.progressReport == nil)
        }
    }
#endif
