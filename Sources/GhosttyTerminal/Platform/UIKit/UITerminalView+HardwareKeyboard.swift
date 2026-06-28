//
//  UITerminalView+HardwareKeyboard.swift
//  libghostty-spm
//
//  Physical keyboard support:
//  - Detect hardware keyboard connection so the input accessory bar can be
//    hidden while one is attached (see `inputAccessoryView`).
//  - Force key repeat on press-and-hold instead of iOS's accent (variant)
//    menu, which is unwanted in a terminal.
//
//  iOS does not auto-repeat held keys through `pressesBegan`, so we drive a
//  manual repeat timer. Mac Catalyst repeats natively and is excluded.
//

#if canImport(UIKit) && !targetEnvironment(macCatalyst)
    import GhosttyKit
    import UIKit

    #if canImport(GameController)
        import GameController
    #endif

    extension UITerminalView {
        // MARK: - Detection

        func setupHardwareKeyboardObservers() {
            #if canImport(GameController)
                updateHardwareKeyboardConnected(GCKeyboard.coalesced != nil)
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(handleHardwareKeyboardDidConnect),
                    name: .GCKeyboardDidConnect,
                    object: nil
                )
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(handleHardwareKeyboardDidDisconnect),
                    name: .GCKeyboardDidDisconnect,
                    object: nil
                )
            #endif
        }

        #if canImport(GameController)
            @objc private func handleHardwareKeyboardDidConnect(_: Notification) {
                updateHardwareKeyboardConnected(true)
            }

            @objc private func handleHardwareKeyboardDidDisconnect(_: Notification) {
                // Another keyboard may still be attached; re-query coalesced state.
                updateHardwareKeyboardConnected(GCKeyboard.coalesced != nil)
            }
        #endif

        func updateHardwareKeyboardConnected(_ connected: Bool) {
            guard hardwareKeyboardConnected != connected else { return }
            hardwareKeyboardConnected = connected
            TerminalDebugLog.log(.input, "hardware keyboard connected=\(connected)")
            if !connected { stopKeyRepeat() }
            // Re-evaluate the accessory bar; only has effect while first responder.
            if isFirstResponder { reloadInputViews() }
        }

        // MARK: - Forced Key Repeat

        func beginKeyRepeat(for key: UIKey) {
            guard forcesHardwareKeyRepeat else { return }
            guard !Self.isModifierUsage(key.keyCode) else { return }
            stopKeyRepeat()
            repeatingKey = key
            keyRepeatTimer = Timer.scheduledTimer(
                timeInterval: max(keyRepeatInitialDelay, 0.05),
                target: self,
                selector: #selector(keyRepeatInitialFired),
                userInfo: nil,
                repeats: false
            )
        }

        func endKeyRepeat(for key: UIKey) {
            guard let repeatingKey, repeatingKey.keyCode == key.keyCode else { return }
            stopKeyRepeat()
        }

        func stopKeyRepeat() {
            keyRepeatTimer?.invalidate()
            keyRepeatTimer = nil
            repeatingKey = nil
        }

        @objc private func keyRepeatInitialFired() {
            fireKeyRepeat()
            // Only escalate to a steady repeat if the key is still held.
            guard repeatingKey != nil else { return }
            keyRepeatTimer = Timer.scheduledTimer(
                timeInterval: max(keyRepeatInterval, 0.01),
                target: self,
                selector: #selector(keyRepeatTick),
                userInfo: nil,
                repeats: true
            )
        }

        @objc private func keyRepeatTick() {
            fireKeyRepeat()
        }

        private func fireKeyRepeat() {
            guard let key = repeatingKey, surface != nil else {
                stopKeyRepeat()
                return
            }
            handleKeyPress(key, action: GHOSTTY_ACTION_REPEAT)
        }

        static func isModifierUsage(_ usage: UIKeyboardHIDUsage) -> Bool {
            switch usage {
            case .keyboardLeftShift, .keyboardRightShift,
                 .keyboardLeftControl, .keyboardRightControl,
                 .keyboardLeftAlt, .keyboardRightAlt,
                 .keyboardLeftGUI, .keyboardRightGUI,
                 .keyboardCapsLock:
                true
            default:
                false
            }
        }
    }
#endif
