// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import AppKit
import Foundation
import Testing

@testable import SPFKUtils

/// An action sent while no window is key, as when the app is not active, still reaches the main
/// window's responder chain.
@Suite(.serialized)
@MainActor
struct FirstResponderTests {
    final class RecordingView: NSView {
        var undoCount = 0

        override var acceptsFirstResponder: Bool { true }

        @objc func undo(_ sender: Any?) {
            undoCount += 1
        }
    }

    @Test func anActionWithNoKeyWindowReachesTheMainWindowsFirstResponder() async throws {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 200),
            styleMask: [.titled], backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        defer { window.close() }

        let view = RecordingView(frame: window.contentLayoutRect)
        window.contentView = view
        window.orderFront(nil)
        #expect(window.makeFirstResponder(view))
        try #require(NSApp.keyWindow == nil)

        FirstResponder.send(action: .undo)

        for _ in 0 ..< 50 where view.undoCount == 0 {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(view.undoCount == 1)
    }
}
