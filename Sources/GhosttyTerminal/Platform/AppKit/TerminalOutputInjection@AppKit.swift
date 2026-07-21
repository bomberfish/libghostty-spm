#if os(macOS) && canImport(AppKit) && !canImport(UIKit)
    import GhosttyKit

    public extension TerminalSurface {
        /// Feeds trusted output directly through Ghostty's terminal parser.
        /// This bypasses the child PTY and is intended for host presentation
        /// controls such as cursor positioning, not untrusted process output.
        @discardableResult
        func injectTerminalOutput(_ text: String) -> Bool {
            guard let rawValue else { return false }
            let bytes = Array(text.utf8)
            guard !bytes.isEmpty else { return true }
            bytes.withUnsafeBufferPointer { buffer in
                ghostty_surface_write_buffer(rawValue, buffer.baseAddress, UInt(buffer.count))
            }
            return true
        }
    }

    public extension TerminalViewState {
        @discardableResult
        func injectTerminalOutput(_ text: String) -> Bool {
            surface?.injectTerminalOutput(text) ?? false
        }
    }

    public extension AppTerminalView {
        @discardableResult
        func injectTerminalOutput(_ text: String) -> Bool {
            surface?.injectTerminalOutput(text) ?? false
        }
    }
#endif
