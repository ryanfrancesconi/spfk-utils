// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
import AppKit

/// Debugging instrumentation: prints every first-responder change on a window, whether it happened
/// while an event was being dispatched, and the call stack that made it. Filter the console on
/// `FRPROBE`; the frames are mangled, so pipe them through `xcrun swift-demangle --simplified`.
/// Observation ends when the probe is released.
@MainActor
public final class FirstResponderProbe {
    private weak var window: NSWindow?
    private weak var lastResponder: NSResponder?
    private var observation: NSKeyValueObservation?
    private let stackDepth: Int

    public init(window: NSWindow, stackDepth: Int = 25) {
        self.window = window
        self.stackDepth = stackDepth
        lastResponder = window.firstResponder

        // KVO fires synchronously inside `makeFirstResponder`, so the stack names the caller.
        observation = window.observe(\.firstResponder, options: [.new]) { [weak self] _, _ in
            MainActor.assumeIsolated { self?.firstResponderChanged() }
        }
    }

    private func firstResponderChanged() {
        let responder = window?.firstResponder
        guard responder !== lastResponder else { return }
        defer { lastResponder = responder }

        let symbols = Thread.callStackSymbols

        print("FRPROBE \(Self.describe(lastResponder)) -> \(Self.describe(responder)) | \(Self.dispatchContext(symbols))")

        // Everything up to the last KVO frame is this probe and the notification delivery.
        let start = (symbols.lastIndex { $0.contains("NSKeyValue") } ?? 0) + 1
        for frame in symbols.dropFirst(start).prefix(stackDepth) {
            print("FRPROBE   \(frame)")
        }
    }

    /// An input-driven change has `sendEvent:` on its stack; anything else arrived asynchronously,
    /// whatever `NSApp.currentEvent` still holds.
    private static func dispatchContext(_ symbols: [String]) -> String {
        guard symbols.contains(where: { $0.contains("[NSApplication sendEvent:]") }) else {
            return "outside event dispatch"
        }
        let event = NSApp.currentEvent.map { name(of: $0.type) } ?? "unknown"
        return "during \(event)"
    }

    private static func name(of type: NSEvent.EventType) -> String {
        switch type {
        case .leftMouseDown: "leftMouseDown"
        case .leftMouseUp: "leftMouseUp"
        case .rightMouseDown: "rightMouseDown"
        case .rightMouseUp: "rightMouseUp"
        case .leftMouseDragged: "leftMouseDragged"
        case .mouseMoved: "mouseMoved"
        case .keyDown: "keyDown"
        case .keyUp: "keyUp"
        case .flagsChanged: "flagsChanged"
        case .scrollWheel: "scrollWheel"
        case .appKitDefined: "appKitDefined"
        default: "event \(type.rawValue)"
        }
    }

    /// A field editor is reported as the control it is editing for, since that is what took focus.
    private static func describe(_ responder: NSResponder?) -> String {
        guard let responder else { return "nil" }

        if let textView = responder as? NSTextView, textView.isFieldEditor,
           let delegate = textView.delegate as? NSResponder
        {
            return "fieldEditor(\(describe(delegate)))"
        }

        var text = String(describing: type(of: responder))

        if let view = responder as? NSView {
            if let identifier = view.identifier?.rawValue { text += " id=\(identifier)" }

            var ancestors: [String] = []
            var parent = view.superview
            while let current = parent, ancestors.count < 4 {
                ancestors.append(String(describing: type(of: current)))
                parent = current.superview
            }
            if !ancestors.isEmpty { text += " in " + ancestors.joined(separator: " < ") }
        }

        return text
    }
}
#endif
