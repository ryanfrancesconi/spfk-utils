// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import AppKit
    import Foundation
    import SPFKBase
    import Testing

    @testable import SPFKUtils

    @Suite
    final class NSScreenClampTests {
        private let primary = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        private let secondaryRight = NSRect(x: 1920, y: 0, width: 1920, height: 1080)
        private let secondaryLeft = NSRect(x: -1920, y: 0, width: 1920, height: 1080)
        private let bottomDock = NSRect(x: 0, y: 50, width: 1920, height: 1030)

        @Test func overhangingRightEdgeIsMovedNotResized() {
            let result = NSScreen.clamp(NSRect(x: 1600, y: 100, width: 400, height: 300), within: primary)
            #expect(result == NSRect(x: 1520, y: 100, width: 400, height: 300))
        }

        @Test func validRectOnSecondaryScreenIsUntouched() {
            let rect = NSRect(x: 2000, y: 100, width: 400, height: 300)
            #expect(NSScreen.clamp(rect, within: secondaryRight) == rect)
        }

        @Test func oversizedRectOnScreenLeftOfOriginEndsFullyOnScreen() {
            let result = NSScreen.clamp(NSRect(x: -1900, y: 100, width: 4000, height: 300), within: secondaryLeft)
            #expect(result == NSRect(x: -1920, y: 100, width: 1920, height: 300))
        }

        /// The available height is `maxY - minY`, not the screen height, so the Dock's inset must
        /// not be subtracted a second time from a window that already fits.
        @Test func rectInsideAScreenWithABottomDockIsUntouched() {
            let rect = NSRect(x: 100, y: 500, width: 400, height: 560)
            #expect(NSScreen.clamp(rect, within: bottomDock) == rect)
        }

        @Test func rectLargerThanTheScreenInBothAxesBecomesTheScreen() {
            let result = NSScreen.clamp(NSRect(x: -500, y: -500, width: 5000, height: 5000), within: bottomDock)
            #expect(result == bottomDock)
        }

        @Test func rectFullyInsideIsReturnedUnchanged() {
            let rect = NSRect(x: 200, y: 200, width: 800, height: 600)
            #expect(NSScreen.clamp(rect, within: primary) == rect)
        }

        @Test func rectFlushAgainstTheRightEdgeStaysFlush() {
            let rect = NSRect(x: 1520, y: 0, width: 400, height: 300)
            #expect(NSScreen.clamp(rect, within: primary) == rect)
        }
    }
#endif
