//
//  TerminalInspectorMetalView+Input.swift
//  libghostty-spm
//
//  Pointer and keyboard forwarding for the inspector view. Catalyst follows
//  the UIKit branch (per the project's platform-branching rule).
//

import GhosttyKit

#if canImport(UIKit)
    import UIKit

    extension TerminalInspectorMetalView {
        override var canBecomeFirstResponder: Bool { true }

        override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
            guard let touch = touches.first,
                  let inspector = viewState?.surface?.inspector()
            else { return }
            if !isFirstResponder { becomeFirstResponder() }
            setInspectorFocus(true)
            let point = touch.location(in: self)
            inspector.mousePosition(x: Double(point.x), y: Double(point.y))
            inspector.mouseButton(true, button: .left)
        }

        override func touchesMoved(_ touches: Set<UITouch>, with _: UIEvent?) {
            guard let touch = touches.first,
                  let inspector = viewState?.surface?.inspector()
            else { return }
            let point = touch.location(in: self)
            inspector.mousePosition(x: Double(point.x), y: Double(point.y))
        }

        override func touchesEnded(_ touches: Set<UITouch>, with _: UIEvent?) {
            guard let touch = touches.first,
                  let inspector = viewState?.surface?.inspector()
            else { return }
            let point = touch.location(in: self)
            inspector.mousePosition(x: Double(point.x), y: Double(point.y))
            inspector.mouseButton(false, button: .left)
        }

        override func touchesCancelled(_: Set<UITouch>, with _: UIEvent?) {
            viewState?.surface?.inspector()?.mouseButton(false, button: .left)
        }

        // MARK: Hardware keyboard

        override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            var handled = false
            for press in presses {
                guard let key = press.key else { continue }
                handleInspectorPress(key, action: GHOSTTY_ACTION_PRESS)
                handled = true
            }
            if !handled { super.pressesBegan(presses, with: event) }
        }

        override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            var handled = false
            for press in presses {
                guard let key = press.key else { continue }
                handleInspectorPress(key, action: GHOSTTY_ACTION_RELEASE)
                handled = true
            }
            if !handled { super.pressesEnded(presses, with: event) }
        }

        private func handleInspectorPress(_ key: UIKey, action: ghostty_input_action_e) {
            guard let inspector = viewState?.surface?.inspector() else { return }
            let mods = TerminalInputModifiers(from: key.modifierFlags)

            if let mapped = Self.inspectorKey(forHIDUsage: key.keyCode) {
                inspector.sendKey(action: action, key: mapped, mods: mods.ghosttyMods)
            }

            // Printable text for ImGui text fields. Skip control characters and
            // shortcut chords (cmd/ctrl held); special keys are sent above.
            guard action == GHOSTTY_ACTION_PRESS else { return }
            let chars = key.characters
            if !mods.contains(.super_), !mods.contains(.ctrl), !chars.isEmpty,
               let scalar = chars.unicodeScalars.first,
               scalar.value >= 0x20, scalar.value != 0x7F
            {
                inspector.sendText(chars)
            }
        }

        /// Maps the HID usages ImGui cares about for text navigation/editing to
        /// Ghostty's translated key enum. Printable keys arrive as text instead.
        static func inspectorKey(forHIDUsage usage: UIKeyboardHIDUsage) -> ghostty_input_key_e? {
            switch usage {
            case .keyboardDeleteOrBackspace: GHOSTTY_KEY_BACKSPACE
            case .keyboardReturnOrEnter, .keypadEnter: GHOSTTY_KEY_ENTER
            case .keyboardTab: GHOSTTY_KEY_TAB
            case .keyboardEscape: GHOSTTY_KEY_ESCAPE
            case .keyboardDeleteForward: GHOSTTY_KEY_DELETE
            case .keyboardLeftArrow: GHOSTTY_KEY_ARROW_LEFT
            case .keyboardRightArrow: GHOSTTY_KEY_ARROW_RIGHT
            case .keyboardDownArrow: GHOSTTY_KEY_ARROW_DOWN
            case .keyboardUpArrow: GHOSTTY_KEY_ARROW_UP
            case .keyboardHome: GHOSTTY_KEY_HOME
            case .keyboardEnd: GHOSTTY_KEY_END
            default: nil
            }
        }
    }

#elseif canImport(AppKit)
    import AppKit

    extension TerminalInspectorMetalView {
        override var acceptsFirstResponder: Bool { true }

        override func becomeFirstResponder() -> Bool {
            let result = super.becomeFirstResponder()
            if result { setInspectorFocus(true) }
            return result
        }

        override func resignFirstResponder() -> Bool {
            let result = super.resignFirstResponder()
            if result { setInspectorFocus(false) }
            return result
        }

        override func updateTrackingAreas() {
            trackingAreas.forEach { removeTrackingArea($0) }
            addTrackingArea(NSTrackingArea(
                rect: bounds,
                options: [.mouseMoved, .inVisibleRect, .activeAlways],
                owner: self,
                userInfo: nil
            ))
        }

        override func mouseDown(with event: NSEvent) { sendButton(true, .left, event) }
        override func mouseUp(with event: NSEvent) { sendButton(false, .left, event) }
        override func rightMouseDown(with event: NSEvent) { sendButton(true, .right, event) }
        override func rightMouseUp(with event: NSEvent) { sendButton(false, .right, event) }
        override func mouseMoved(with event: NSEvent) { sendPosition(event) }
        override func mouseDragged(with event: NSEvent) { sendPosition(event) }
        override func rightMouseDragged(with event: NSEvent) { sendPosition(event) }

        override func scrollWheel(with event: NSEvent) {
            guard let inspector = viewState?.surface?.inspector() else { return }
            let momentum = TerminalScrollModifiers.momentumFrom(phase: event.momentumPhase)
            let mods = TerminalScrollModifiers(
                precision: event.hasPreciseScrollingDeltas,
                momentum: momentum
            )
            inspector.mouseScroll(
                x: Double(event.scrollingDeltaX),
                y: Double(event.scrollingDeltaY),
                mods: mods
            )
        }

        override func keyDown(with event: NSEvent) {
            guard let inspector = viewState?.surface?.inspector() else { return }
            let mods = TerminalInputModifiers(from: event.modifierFlags)
            let action: ghostty_input_action_e = event.isARepeat
                ? GHOSTTY_ACTION_REPEAT : GHOSTTY_ACTION_PRESS

            if let key = Self.inspectorKey(forKeyCode: event.keyCode) {
                inspector.sendKey(action: action, key: key, mods: mods.ghosttyMods)
            }

            // Forward printable text for ImGui text fields. Skip control
            // characters and shortcut chords (cmd/ctrl held).
            if !mods.contains(.super_), !mods.contains(.ctrl),
               let chars = event.characters, !chars.isEmpty,
               let scalar = chars.unicodeScalars.first,
               scalar.value >= 0x20, scalar.value != 0x7F
            {
                inspector.sendText(chars)
            }
        }

        override func keyUp(with event: NSEvent) {
            guard let inspector = viewState?.surface?.inspector(),
                  let key = Self.inspectorKey(forKeyCode: event.keyCode)
            else { return }
            let mods = TerminalInputModifiers(from: event.modifierFlags)
            inspector.sendKey(action: GHOSTTY_ACTION_RELEASE, key: key, mods: mods.ghosttyMods)
        }

        private func sendButton(_ pressed: Bool, _ button: TerminalMouseButton, _ event: NSEvent) {
            if pressed { window?.makeFirstResponder(self) }
            guard let inspector = viewState?.surface?.inspector() else { return }
            sendPosition(event)
            inspector.mouseButton(
                pressed,
                button: button,
                mods: TerminalInputModifiers(from: event.modifierFlags)
            )
        }

        private func sendPosition(_ event: NSEvent) {
            guard let inspector = viewState?.surface?.inspector() else { return }
            let point = convert(event.locationInWindow, from: nil)
            // Ghostty expects a top-left origin; AppKit views are bottom-left.
            inspector.mousePosition(x: Double(point.x), y: Double(bounds.height - point.y))
        }

        /// Maps the macOS virtual keycodes that ImGui cares about for text
        /// navigation/editing to Ghostty's translated key enum. Printable keys
        /// are delivered separately as text.
        static func inspectorKey(forKeyCode keyCode: UInt16) -> ghostty_input_key_e? {
            switch keyCode {
            case 51: GHOSTTY_KEY_BACKSPACE
            case 36, 76: GHOSTTY_KEY_ENTER
            case 48: GHOSTTY_KEY_TAB
            case 53: GHOSTTY_KEY_ESCAPE
            case 117: GHOSTTY_KEY_DELETE
            case 123: GHOSTTY_KEY_ARROW_LEFT
            case 124: GHOSTTY_KEY_ARROW_RIGHT
            case 125: GHOSTTY_KEY_ARROW_DOWN
            case 126: GHOSTTY_KEY_ARROW_UP
            case 115: GHOSTTY_KEY_HOME
            case 119: GHOSTTY_KEY_END
            default: nil
            }
        }
    }
#endif
