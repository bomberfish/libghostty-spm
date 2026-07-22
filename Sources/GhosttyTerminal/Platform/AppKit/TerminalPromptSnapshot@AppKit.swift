#if os(macOS) && canImport(AppKit) && !canImport(UIKit)
    import GhosttyKit

    public extension TerminalSurface {
        /// Returns the newest OSC 133 prompt with colors and text attributes
        /// encoded as VT SGR sequences. Returns nil before shell integration
        /// has marked a prompt.
        func readLatestPromptVT() -> String? {
            #if arch(arm64)
            guard let rawValue else { return nil }
            var out = ghostty_text_s()
            guard ghostty_surface_read_latest_prompt(rawValue, &out) else { return nil }
            defer { ghostty_surface_free_text(rawValue, &out) }
            guard let text = out.text, out.text_len > 0 else { return "" }
            let bytes = UnsafeBufferPointer(start: text, count: Int(out.text_len))
                .map { UInt8(bitPattern: $0) }
            return String(decoding: bytes, as: UTF8.self)
            #else
            return nil
            #endif
        }
    }

    public extension TerminalViewState {
        func readLatestPromptVT() -> String? {
            surface?.readLatestPromptVT()
        }
    }

    public extension AppTerminalView {
        func readLatestPromptVT() -> String? {
            surface?.readLatestPromptVT()
        }
    }
#endif
