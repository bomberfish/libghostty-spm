#if os(macOS) && canImport(AppKit) && !canImport(UIKit)
    import GhosttyKit

    /// Non-text keys a macOS host can inject through Ghostty's terminal-aware
    /// key encoder. Use ``TerminalViewState/sendKey(_:modifiers:)`` when raw
    /// text paste semantics are not appropriate, such as submitting a pasted
    /// command with Return.
    public enum TerminalKey: Sendable {
        case enter
        case escape
        case tab
        case backspace
        case delete
        case arrowUp
        case arrowDown
        case arrowLeft
        case arrowRight
        case home
        case end
        case pageUp
        case pageDown

        var ghosttyValue: ghostty_input_key_e {
            switch self {
            case .enter: GHOSTTY_KEY_ENTER
            case .escape: GHOSTTY_KEY_ESCAPE
            case .tab: GHOSTTY_KEY_TAB
            case .backspace: GHOSTTY_KEY_BACKSPACE
            case .delete: GHOSTTY_KEY_DELETE
            case .arrowUp: GHOSTTY_KEY_ARROW_UP
            case .arrowDown: GHOSTTY_KEY_ARROW_DOWN
            case .arrowLeft: GHOSTTY_KEY_ARROW_LEFT
            case .arrowRight: GHOSTTY_KEY_ARROW_RIGHT
            case .home: GHOSTTY_KEY_HOME
            case .end: GHOSTTY_KEY_END
            case .pageUp: GHOSTTY_KEY_PAGE_UP
            case .pageDown: GHOSTTY_KEY_PAGE_DOWN
            }
        }

        var unshiftedCodepoint: UInt32 {
            switch self {
            case .enter: 0x0D
            case .escape: 0x1B
            case .tab: 0x09
            case .backspace: 0x7F
            case .delete, .arrowUp, .arrowDown, .arrowLeft, .arrowRight,
                 .home, .end, .pageUp, .pageDown:
                0
            }
        }
    }

    public extension TerminalSurface {
        /// Injects one press/release pair through Ghostty's key encoder.
        /// Returns false when the surface is detached.
        @discardableResult
        func sendKey(
            _ key: TerminalKey,
            modifiers: TerminalInputModifiers = []
        ) -> Bool {
            guard rawValue != nil else { return false }

            var event = ghostty_input_key_s()
            event.action = GHOSTTY_ACTION_PRESS
            event.mods = modifiers.ghosttyMods
            event.consumed_mods = GHOSTTY_MODS_NONE
            event.keycode = TerminalHardwareKeyRouter.appKitKeyCode(for: key.ghosttyValue)
            event.text = nil
            event.unshifted_codepoint = key.unshiftedCodepoint
            event.composing = false
            _ = sendKeyEvent(event)

            event.action = GHOSTTY_ACTION_RELEASE
            _ = sendKeyEvent(event)
            return true
        }
    }

    public extension TerminalViewState {
        /// Injects a terminal-aware non-text key into the attached surface.
        @discardableResult
        func sendKey(
            _ key: TerminalKey,
            modifiers: TerminalInputModifiers = []
        ) -> Bool {
            surface?.sendKey(key, modifiers: modifiers) ?? false
        }
    }

    public extension AppTerminalView {
        /// Injects a terminal-aware non-text key into the attached surface.
        @discardableResult
        func sendKey(
            _ key: TerminalKey,
            modifiers: TerminalInputModifiers = []
        ) -> Bool {
            surface?.sendKey(key, modifiers: modifiers) ?? false
        }
    }
#endif
