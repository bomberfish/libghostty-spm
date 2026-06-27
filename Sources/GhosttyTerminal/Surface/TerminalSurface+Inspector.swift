//
//  TerminalSurface+Inspector.swift
//  libghostty-spm
//
//  Inspector access for a surface.
//

import GhosttyKit

public extension TerminalSurface {
    /// Returns the surface's terminal inspector, creating it on first access.
    ///
    /// The returned ``TerminalInspector`` is cached and owned by this surface;
    /// it is freed automatically when the surface is freed. Returns `nil` if
    /// the surface has already been freed.
    ///
    /// To display it, hand the surface (or its ``TerminalViewState``) to a
    /// ``TerminalInspectorView``.
    func inspector() -> TerminalInspector? {
        if let cachedInspector, cachedInspector.isValid {
            return cachedInspector
        }
        cachedInspector = nil

        guard let raw = rawValue else {
            TerminalDebugLog.log(.lifecycle, "inspector ignored: missing surface")
            return nil
        }
        guard let handle = ghostty_surface_inspector(raw) else {
            TerminalDebugLog.log(.lifecycle, "inspector creation failed")
            return nil
        }

        let inspector = TerminalInspector(handle: handle, owner: self)
        cachedInspector = inspector
        TerminalDebugLog.log(.lifecycle, "inspector created")
        return inspector
    }

    /// Frees the inspector associated with this surface, if any.
    ///
    /// Safe to call repeatedly. The inspector is also freed automatically when
    /// the surface itself is freed, so calling this is only necessary to
    /// release inspector resources earlier.
    func freeInspector() {
        guard let raw = rawValue else { return }
        cachedInspector = nil
        TerminalDebugLog.log(.lifecycle, "inspector free")
        ghostty_inspector_free(raw)
    }
}
