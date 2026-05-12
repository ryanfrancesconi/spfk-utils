// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import Foundation
    import SPFKBase
    import SPFKTesting
    import SPFKUtils
    import Testing

    class HardwareTests {
        @Test func chip() async throws {
            #expect(HardwareInfo.chip != nil)
            #expect(HardwareInfo.chipname?.hasPrefix("Apple") == true) // Apple M1 Max

            Log.debug(HardwareInfo.description)
        }

        @Test func uuid() async throws {
            let uuid = try #require(HardwareInfo.hardwareUUID)
            Log.debug("hardwareUUID:", uuid)
        }
    }
#endif
