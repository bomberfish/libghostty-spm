//
//  TerminalInspectorView.swift
//  libghostty-spm
//
//  SwiftUI entry point for the terminal inspector. Drop this alongside a
//  ``TerminalSurfaceView`` (e.g. in a split or sheet) using the same
//  ``TerminalViewState``.
//

import SwiftUI

/// A SwiftUI view that renders the ImGui terminal inspector for a
/// ``TerminalViewState``'s surface.
///
/// ```swift
/// HStack {
///     TerminalSurfaceView(context: state)
///     if showInspector {
///         TerminalInspectorView(state)
///     }
/// }
/// ```
///
/// The inspector resolves lazily from the state's surface, so it works whether
/// it is shown before or after the surface attaches, and stops rendering if the
/// surface goes away.
public struct TerminalInspectorView: View {
    @ObservedObject private var state: TerminalViewState

    public init(_ state: TerminalViewState) {
        self.state = state
    }

    public var body: some View {
        TerminalInspectorRepresentable(viewState: state)
    }
}

#if canImport(UIKit)
    import UIKit

    struct TerminalInspectorRepresentable: UIViewRepresentable {
        let viewState: TerminalViewState

        func makeUIView(context _: Context) -> TerminalInspectorMetalView {
            let view = TerminalInspectorMetalView(frame: .zero)
            view.viewState = viewState
            return view
        }

        func updateUIView(_ view: TerminalInspectorMetalView, context _: Context) {
            view.viewState = viewState
        }

        static func dismantleUIView(_ view: TerminalInspectorMetalView, coordinator _: ()) {
            view.setInspectorFocus(false)
        }
    }

#elseif canImport(AppKit)
    import AppKit

    struct TerminalInspectorRepresentable: NSViewRepresentable {
        let viewState: TerminalViewState

        func makeNSView(context _: Context) -> TerminalInspectorMetalView {
            let view = TerminalInspectorMetalView(frame: .zero)
            view.viewState = viewState
            return view
        }

        func updateNSView(_ view: TerminalInspectorMetalView, context _: Context) {
            view.viewState = viewState
        }

        static func dismantleNSView(_ view: TerminalInspectorMetalView, coordinator _: ()) {
            view.setInspectorFocus(false)
        }
    }
#endif
