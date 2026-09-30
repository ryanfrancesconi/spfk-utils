// Copyright Ryan Francesconi. All Rights Reserved.

#if os(macOS)
    import CoreGraphics
    import Foundation
    import Testing

    @testable import SPFKUtils

    /// A display link needs an active display, which a sleeping or headless machine does not have.
    private var hasActiveDisplay: Bool {
        var count: UInt32 = 0
        return CGGetActiveDisplayList(0, nil, &count) == .success && count > 0
    }

    struct DisplayLinkTests {
        /// Creating one either succeeds or throws; with no active display it throws rather than
        /// trapping on the source it had already made.
        @Test func creatingADisplayLinkNeverCrashes() {
            _ = try? DisplayLink()
        }

        @Test(.enabled(if: hasActiveDisplay, "Needs an active display"))
        func releasingACancelledDisplayLinkDoesNotCrash() throws {
            do {
                let link = try DisplayLink()
                link.start()
                link.cancel()
                #expect(!link.running)
            }
        }

        @Test(.enabled(if: hasActiveDisplay, "Needs an active display"))
        func releasingASuspendedDisplayLinkDoesNotCrash() throws {
            do {
                let link = try DisplayLink()
                link.start()
                link.suspend()
            }
        }
    }
#endif
