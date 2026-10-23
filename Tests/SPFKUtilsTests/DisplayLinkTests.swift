// Copyright Ryan Francesconi. All Rights Reserved.

// `DisplayLink` is deprecated in macOS 14, and `@Test` cannot be applied to a deprecated declaration.
// So the tests' bodies live in a deprecated conformance, which the suite reaches through a dynamic
// cast — naming the conformance statically would warn too. Delete this file with `DisplayLink`.

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

    private protocol DisplayLinkScenarios {
        func create()
        func releaseCancelled() throws
        func releaseSuspended() throws
    }

    private struct LegacyDisplayLinkScenarios {}

    @available(macOS, deprecated: 14.0)
    extension LegacyDisplayLinkScenarios: DisplayLinkScenarios {
        func create() {
            _ = try? DisplayLink()
        }

        func releaseCancelled() throws {
            let link = try DisplayLink()
            link.start()
            link.cancel()
            #expect(!link.running)
        }

        func releaseSuspended() throws {
            let link = try DisplayLink()
            link.start()
            link.suspend()
        }
    }

    struct DisplayLinkTests {
        private let scenarios = LegacyDisplayLinkScenarios() as Any as? DisplayLinkScenarios

        /// Creating one either succeeds or throws; with no active display it throws rather than
        /// trapping on the source it had already made.
        @Test func creatingADisplayLinkNeverCrashes() throws {
            try #require(scenarios).create()
        }

        @Test(.enabled(if: hasActiveDisplay, "Needs an active display"))
        func releasingACancelledDisplayLinkDoesNotCrash() throws {
            try #require(scenarios).releaseCancelled()
        }

        @Test(.enabled(if: hasActiveDisplay, "Needs an active display"))
        func releasingASuspendedDisplayLinkDoesNotCrash() throws {
            try #require(scenarios).releaseSuspended()
        }
    }
#endif
