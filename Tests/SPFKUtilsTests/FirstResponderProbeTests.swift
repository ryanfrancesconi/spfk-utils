// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
import AppKit
import Foundation
import Testing
@testable import SPFKUtils

@MainActor
struct FirstResponderProbeTests {
    @Test func probeIsReleasedWhileItsWindowLives() {
        let window = NSWindow(contentRect: .init(x: 0, y: 0, width: 100, height: 100), styleMask: [.titled], backing: .buffered, defer: false)
        weak var weakProbe: FirstResponderProbe?

        autoreleasepool {
            let probe = FirstResponderProbe(window: window)
            window.makeFirstResponder(window.contentView)
            weakProbe = probe
        }

        #expect(weakProbe == nil)
        window.makeFirstResponder(nil)
    }
}
#endif
