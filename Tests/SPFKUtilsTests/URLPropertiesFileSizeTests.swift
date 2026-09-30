// Copyright Ryan Francesconi. All Rights Reserved.

#if os(macOS)
    import Foundation
    import SPFKBase
    import SPFKTesting
    import Testing

    @testable import SPFKUtils

    /// `fileSize` is the file's own length, as Finder shows it; the size on disk is kept apart.
    @Suite(.tags(.file))
    final class URLPropertiesFileSizeTests: BinTestCase {
        @Test func aOneByteFileReportsOneByte() throws {
            deleteBinOnExit = true
            let url = bin.appendingPathComponent("one-byte.txt")
            try Data([0x41]).write(to: url)

            let properties = URLProperties(url: url)

            #expect(properties.fileSize == 1)
            #expect(properties.allocatedSize == url.regularFileAllocatedSize)
            #expect((properties.allocatedSize ?? 0) >= 1)
        }

        @Test func bothSizesSurviveEncoding() throws {
            deleteBinOnExit = true
            let url = bin.appendingPathComponent("two-bytes.txt")
            try Data([0x41, 0x42]).write(to: url)

            let properties = URLProperties(url: url)
            let decoded = try JSONDecoder().decode(URLProperties.self, from: JSONEncoder().encode(properties))

            #expect(decoded.fileSize == properties.fileSize)
            #expect(decoded.allocatedSize == properties.allocatedSize)
        }

        /// A record written before the logical size was stored reads its allocated size for both.
        @Test func aRecordWithoutALogicalSizeReadsTheAllocatedSize() throws {
            let json = Data(#"{"url":"file:///tmp/old.wav","fileSize":4096}"#.utf8)
            let decoded = try JSONDecoder().decode(URLProperties.self, from: json)

            #expect(decoded.allocatedSize == 4096)
            #expect(decoded.fileSize == 4096)
        }
    }
#endif
