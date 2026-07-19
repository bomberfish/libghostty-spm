#if os(macOS) && canImport(AppKit) && !canImport(UIKit)
    import Darwin
    import GhosttyKit

    public extension TerminalViewState {
        var foregroundPid: pid_t? {
            surface?.foregroundPid
        }

        var ttyName: String? {
            surface?.ttyName
        }

        var needsConfirmQuit: Bool {
            surface?.needsConfirmQuit ?? false
        }

        var processExited: Bool {
            surface?.processExited ?? true
        }

        @discardableResult
        func requestClose() -> Bool {
            guard let surface else { return false }
            surface.requestClose()
            return true
        }
    }

    extension TerminalSurface {
        var needsConfirmQuit: Bool {
            guard let rawValue else { return false }
            return ghostty_surface_needs_confirm_quit(rawValue)
        }

        var processExited: Bool {
            guard let rawValue else { return true }
            return ghostty_surface_process_exited(rawValue)
        }

        func requestClose() {
            guard let rawValue else { return }
            ghostty_surface_request_close(rawValue)
        }
    }
#endif
