//
//  TerminalViewState+Delegate.swift
//  libghostty-spm
//
//  Created by Lakr233 on 2026/3/16.
//

import Foundation
import GhosttyKit

extension TerminalViewState:
    TerminalSurfaceTitleDelegate,
    TerminalSurfaceGridResizeDelegate,
    TerminalSurfaceFocusDelegate,
    TerminalSurfaceCloseDelegate,
    TerminalSurfaceBellDelegate,
    TerminalSurfaceDesktopNotificationDelegate,
    TerminalSurfacePwdDelegate,
    TerminalSurfaceScrollbarDelegate,
    TerminalSurfaceCommandFinishedDelegate,
    TerminalSurfaceLifecycleDelegate
{
    public func terminalDidChangeTitle(_ title: String) {
        applyDelegateUpdate { $0.title = title }
    }

    public func terminalDidResize(_ size: TerminalGridMetrics) {
        applyDelegateUpdate { $0.surfaceSize = size }
    }

    public func terminalDidChangeFocus(_ focused: Bool) {
        applyDelegateUpdate { $0.isFocused = focused }
    }

    public func terminalDidClose(processAlive: Bool) {
        applyDelegateUpdate { $0.onClose?(processAlive) }
    }

    public func terminalDidRingBell() {
        applyDelegateUpdate {
            $0.bellCount += 1
            $0.lastBellAt = Date()
        }
    }

    public func terminalDidRequestDesktopNotification(title: String, body: String) {
        applyDelegateUpdate {
            $0.lastDesktopNotificationTitle = title
            $0.lastDesktopNotificationBody = body
            $0.lastDesktopNotificationAt = Date()
        }
    }

    public func terminalDidChangeWorkingDirectory(_ path: String) {
        applyDelegateUpdate { $0.workingDirectory = path }
    }

    public func terminalDidUpdateScrollbar(_ scrollbar: TerminalScrollbar) {
        applyDelegateUpdate { $0.scrollbar = scrollbar }
    }

    public func terminalDidFinishCommand(exitCode: Int?, durationNanos: UInt64) {
        applyDelegateUpdate {
            $0.lastCommandExitCode = exitCode
            $0.lastCommandDurationNanos = durationNanos
            #if os(macOS) && canImport(AppKit) && !canImport(UIKit)
                $0.commandFinishedSequence &+= 1
                $0.progressReport = nil
            #endif
        }
    }

    public func terminalDidAttachSurface(_ surface: TerminalSurface) {
        applyDelegateUpdate { $0.surface = surface }
    }

    public func terminalDidDetachSurface() {
        applyDelegateUpdate {
            $0.surface = nil
            $0.scrollbar = nil
        }
    }

    private func applyDelegateUpdate(
        _ update: @escaping @MainActor (TerminalViewState) -> Void
    ) {
        #if os(macOS) && canImport(AppKit) && !canImport(UIKit)
            // AppKit may synchronously emit resize/focus/config actions while
            // NSViewRepresentable is in updateNSView. Publishing there violates
            // SwiftUI's update contract, so commit observable state next turn.
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                update(self)
            }
        #else
            update(self)
        #endif
    }
}

#if os(macOS) && canImport(AppKit) && !canImport(UIKit)
    extension TerminalViewState: TerminalSurfaceProgressReportDelegate {
        public func terminalDidReportProgress(
            state: TerminalProgressState,
            percent: Int?
        ) {
            applyDelegateUpdate {
                $0.progressReport = state == .remove
                    ? nil
                    : TerminalProgressReport(state: state, percent: percent)
            }
        }
    }
#endif
