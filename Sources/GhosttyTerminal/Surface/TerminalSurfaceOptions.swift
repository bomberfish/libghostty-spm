//
//  TerminalSurfaceOptions.swift
//  libghostty-spm
//
//  Created by Lakr233 on 2026/3/16.
//

import GhosttyKit

public struct TerminalSurfaceOptions: Sendable {
    public var backend: TerminalSessionBackend
    public var fontSize: Float?
    public var workingDirectory: String?
    /// Extra environment variables set in the child process spawned for this
    /// surface (exec backend). Passed through `ghostty_surface_config_s.env_vars`;
    /// every process launched from the surface's shell inherits them, which lets
    /// embedding hosts tag a surface (e.g. `MYAPP_PANE=<uuid>`) and correlate
    /// externally observed processes back to it.
    public var envVars: [String: String]
    public var context: TerminalSurfaceContext

    /// When `true`, the terminal view does not accept user input — it will not
    /// become first responder, so there is no keyboard (software or hardware),
    /// IME, or input accessory bar. Rendering and programmatic output (e.g.
    /// `InMemoryTerminalSession.receive`) continue normally, and text remains
    /// selectable/scrollable. Useful for non-editable previews. Defaults to
    /// `false`.
    public var readOnly: Bool

    public init(
        backend: TerminalSessionBackend = .exec,
        fontSize: Float? = nil,
        workingDirectory: String? = nil,
        envVars: [String: String] = [:],
        context: TerminalSurfaceContext = .window,
        readOnly: Bool = false
    ) {
        self.backend = backend
        self.fontSize = fontSize
        self.workingDirectory = workingDirectory
        self.envVars = envVars
        self.context = context
        self.readOnly = readOnly
    }

    func isEquivalent(to other: TerminalSurfaceOptions) -> Bool {
        // `readOnly` is intentionally excluded: it only affects view-level
        // input handling, not the underlying surface, so toggling it must not
        // trigger a surface rebuild (which would clear terminal content).
        fontSize == other.fontSize
            && workingDirectory == other.workingDirectory
            && envVars == other.envVars
            && context == other.context
            && backend.isEquivalent(to: other.backend)
    }

    var inMemorySession: InMemoryTerminalSession? {
        guard case let .inMemory(session) = backend else { return nil }
        return session
    }
}
