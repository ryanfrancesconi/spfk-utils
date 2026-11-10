// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
@testable import SPFKUtils
import Testing

struct ZipArchiveTests {
    /// The standard check value for this CRC variant.
    @Test func crc32OfTheCheckStringMatchesTheStandard() {
        #expect(CRC32.checksum(Array("123456789".utf8)) == 0xCBF4_3926)
    }

    @Test func entriesRoundTripStoredAndDeflated() throws {
        let compressible = Data(String(repeating: "keyword ", count: 1000).utf8)
        let tiny = Data("x".utf8)
        let archive = ZipArchive.archive([("a/compressible.xml", compressible), ("tiny", tiny), ("empty", Data())])

        let entries = try ZipArchive.entries(of: archive)

        #expect(entries == ["a/compressible.xml": compressible, "tiny": tiny, "empty": Data()])
        #expect(archive.count < compressible.count / 4)
    }

    @Test func aCorruptedEntryFailsItsChecksum() throws {
        var bytes = [UInt8](ZipArchive.archive([("stored", Data("abc".utf8))]))
        // The stored body follows the 30-byte local header and the 6-byte name.
        bytes[36] ^= 0xFF

        #expect(throws: ZipArchiveError.corruptEntry("stored")) {
            try ZipArchive.entries(of: Data(bytes))
        }
    }

    @Test func dataThatIsNotAnArchiveThrows() {
        #expect(throws: ZipArchiveError.notAZipArchive) {
            try ZipArchive.entries(of: Data("Filename,Description\n".utf8))
        }
    }
}
