#if os(macOS) && canImport(AppKit) && !canImport(UIKit)
    @testable import GhosttyTerminal
    import Testing

    @MainActor
    struct TerminalCursorMetricsTests {
        @Test
        func `view state records cursor geometry`() async {
            let state = TerminalViewState()
            let metrics = TerminalCursorMetrics(x: 12, y: 34, height: 18)

            state.terminalDidMoveCursor(metrics)
            await Task.yield()

            #expect(state.cursorMetrics == metrics)
        }

        @Test
        func `scrollbar identifies the live bottom`() {
            #expect(TerminalScrollbarMetrics(total: 100, offset: 80, length: 20).isAtBottom)
            #expect(!TerminalScrollbarMetrics(total: 100, offset: 40, length: 20).isAtBottom)
            #expect(TerminalScrollbarMetrics(total: 0, offset: 0, length: 0).isAtBottom)
        }

        @Test
        func `view state records scrollbar geometry`() async {
            let state = TerminalViewState()
            let metrics = TerminalScrollbarMetrics(total: 100, offset: 40, length: 20)

            state.terminalDidUpdateScrollbar(metrics)
            await Task.yield()

            #expect(state.scrollbarMetrics == metrics)
        }
    }
#endif
