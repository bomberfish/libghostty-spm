#if os(macOS) && canImport(AppKit) && !canImport(UIKit)
    import GhosttyKit
    @testable import GhosttyTerminal
    import Testing

    @MainActor
    struct TerminalSyntheticKeyTests {
        @Test
        func `unattached state rejects synthetic keys`() {
            let state = TerminalViewState()

            #expect(!state.sendKey(.enter))
        }

        @Test
        func `synthetic keys use native AppKit keycodes`() {
            #expect(
                TerminalHardwareKeyRouter.appKitKeyCode(for: TerminalKey.enter.ghosttyValue) == 0x24
            )
            #expect(
                TerminalHardwareKeyRouter.appKitKeyCode(for: TerminalKey.arrowLeft.ghosttyValue) == 0x7B
            )
        }

        @Test
        func `representable applies read only changes without rebuilding equivalence`() {
            let state = TerminalViewState()
            let view = TerminalView(frame: .zero)
            var configuration = TerminalSurfaceOptions()
            configuration.readOnly = true
            let representable = TerminalViewRepresentable(
                context: state,
                controller: state.controller,
                configuration: configuration,
                focusBinding: nil
            )

            representable.configureView(view, initial: false)

            #expect(view.configuration.readOnly)
        }
    }
#endif
