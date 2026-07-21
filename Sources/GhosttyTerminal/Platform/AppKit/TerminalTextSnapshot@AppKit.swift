#if os(macOS) && canImport(AppKit) && !canImport(UIKit)
    import GhosttyKit

    public extension TerminalSurface {
        /// Returns all written primary-screen text, including scrollback.
        /// This is an expensive synchronous snapshot and should be called only
        /// at coarse lifecycle boundaries such as command completion.
        func readScreenText() -> String? {
            guard let rawValue else { return nil }
            let topLeft = ghostty_point_s(
                tag: GHOSTTY_POINT_SCREEN,
                coord: GHOSTTY_POINT_COORD_TOP_LEFT,
                x: 0,
                y: 0
            )
            let bottomRight = ghostty_point_s(
                tag: GHOSTTY_POINT_SCREEN,
                coord: GHOSTTY_POINT_COORD_BOTTOM_RIGHT,
                x: 0,
                y: 0
            )
            let selection = ghostty_selection_s(
                top_left: topLeft,
                bottom_right: bottomRight,
                rectangle: false
            )

            var out = ghostty_text_s()
            guard ghostty_surface_read_text(rawValue, selection, &out) else { return nil }
            defer { ghostty_surface_free_text(rawValue, &out) }
            guard let text = out.text, out.text_len > 0 else { return "" }
            let bytes = UnsafeBufferPointer(start: text, count: Int(out.text_len))
                .map { UInt8(bitPattern: $0) }
            return String(decoding: bytes, as: UTF8.self)
        }
    }

    public extension TerminalViewState {
        func readScreenText() -> String? {
            surface?.readScreenText()
        }
    }

    public extension AppTerminalView {
        func readScreenText() -> String? {
            surface?.readScreenText()
        }
    }
#endif
