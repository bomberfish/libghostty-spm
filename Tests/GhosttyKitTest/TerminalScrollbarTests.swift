@testable import GhosttyTerminal
import Testing

@MainActor
struct TerminalScrollbarTests {
    @Test
    func `scrollbar identifies the live bottom`() {
        #expect(TerminalScrollbar(total: 100, offset: 80, len: 20).isAtBottom)
        #expect(!TerminalScrollbar(total: 100, offset: 40, len: 20).isAtBottom)
        #expect(TerminalScrollbar(total: 0, offset: 0, len: 0).isAtBottom)
    }

    @Test
    func `view state records scrollbar geometry`() async {
        let state = TerminalViewState()
        let scrollbar = TerminalScrollbar(total: 100, offset: 40, len: 20)

        state.terminalDidUpdateScrollbar(scrollbar)
        await Task.yield()

        #expect(state.scrollbar == scrollbar)
    }
}
