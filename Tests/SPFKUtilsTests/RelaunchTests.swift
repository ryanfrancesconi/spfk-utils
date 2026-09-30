// Copyright Ryan Francesconi. All Rights Reserved.

#if os(macOS)
    import AppKit
    import Foundation
    import Testing

    @testable import SPFKUtils

    struct RelaunchTests {
        /// A helper that cannot start is reported, so the app is not left quit instead of restarted.
        @Test func aHelperThatCannotStartThrows() {
            #expect(throws: (any Error).self) {
                try NSApplication.launchRelaunchHelper(shell: URL(fileURLWithPath: "/nonexistent/shell"))
            }
        }
    }
#endif
