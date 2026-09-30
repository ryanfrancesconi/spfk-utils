// Copyright Ryan Francesconi. All Rights Reserved.

#if os(macOS)
    import Foundation
    import Testing

    @testable import SPFKUtils

    struct ProcessHandlerTests {
        private final class Flag: @unchecked Sendable {
            var isSet = false
        }

        /// A child filling the stderr pipe while stdout is still open must not stall the read.
        @Test func aChildWritingALotToStderrDoesNotHang() async throws {
            let handler = ProcessHandler(
                url: URL(fileURLWithPath: "/bin/sh"),
                args: ["-c", "head -c 200000 /dev/zero | tr '\\0' x 1>&2; echo done"]
            )
            nonisolated(unsafe) let unsafeHandler = handler
            let watchdogFired = Flag()

            let watchdog = Task.detached {
                try await Task.sleep(for: .seconds(5))
                watchdogFired.isSet = true
                unsafeHandler.cancel()
            }

            let output = try handler.run()
            watchdog.cancel()

            #expect(!watchdogFired.isSet)
            #expect(output.contains("done"))
        }
    }
#endif
