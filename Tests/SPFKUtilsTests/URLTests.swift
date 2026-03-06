// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)

    import Numerics
    import SPFKBase
    import SPFKTesting
    import Testing

    class URLTests: BinTestCase {
        @Test func modificationDates() async throws {
            deleteBinOnExit = true

            let url = try copyToBin(url: TestBundleResources.shared.mp3_id3)
            let startDate = try #require(url.modificationDate)

            Log.debug(startDate)
            try await Task.sleep(seconds: 2)

            try url.set(tagColors: [.blue, .gray])
            let modificationDate = try #require(url.modificationDate)
            Log.debug(modificationDate) // +2

            #expect(modificationDate > startDate)
            try await Task.sleep(seconds: 2)

            try url.set(tagNames: ["tag1", "tag2"])
            let modificationDate2 = try #require(url.modificationDate)
            Log.debug(modificationDate2) // +4
            #expect(modificationDate2 > modificationDate)
        }
    }

#endif
