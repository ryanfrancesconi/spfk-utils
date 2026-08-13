// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import Foundation
    import SPFKBase
    import SPFKFileSystem
    import SPFKUtils
    import Testing

    /// The shape a `URLProperties` written before the content/attribute split has on disk: a single
    /// collapsed `modificationDate` holding the later of the two dates.
    private struct LegacyURLProperties: Encodable {
        let url: URL
        let creationDate: Date?
        let modificationDate: Date?
        let fileSize: UInt64?
    }

    @Suite(.tags(.file), .serialized)
    class URLPropertiesLegacyDecodeTests: BinTestCase {
        /// A file whose attribute date is later than its content date, which is the state of any
        /// file that has been copied, tagged or quarantined -- and the one a single collapsed date
        /// cannot represent.
        private func makeFileWithLaterAttributeDate(named name: String) throws -> URL {
            let url = bin.appendingPathComponent(name)
            try Data("content".utf8).write(to: url)

            let value = Array("1".utf8)
            #expect(setxattr(url.path, "com.spongefork.test", value, value.count, 0, 0) == 0)

            return url
        }

        private func legacyData(for url: URL) throws -> Data {
            try JSONEncoder().encode(
                LegacyURLProperties(
                    url: url,
                    creationDate: url.creationDate,
                    modificationDate: FileModificationState(url: url).modificationDate,
                    fileSize: url.regularFileAllocatedSize
                )
            )
        }

        @Test func legacyCollapsedDateReportsNoChangeForUntouchedFile() throws {
            let url = try makeFileWithLaterAttributeDate(named: "untouched.txt")

            let onDisk = FileModificationState(url: url)
            let content = try #require(onDisk.contentModificationDate)
            let attribute = try #require(onDisk.attributeModificationDate)
            #expect(attribute > content, "the xattr write must move the attribute date past the content date")

            let decoded = try JSONDecoder().decode(URLProperties.self, from: legacyData(for: url))

            // Seeding the attribute side from the collapsed value instead would make the record
            // look classifiable and compare each half against a date it never held, reporting a
            // change for every file in a pre-split library.
            #expect(decoded.modificationState.attributeModificationDate == nil)
            #expect(decoded.modificationState.isClassifiable == false)

            #expect(decoded.modification == nil)
        }

        @Test func legacyCollapsedDateStillDetectsContentChange() throws {
            let url = try makeFileWithLaterAttributeDate(named: "rewritten.txt")

            let decoded = try JSONDecoder().decode(URLProperties.self, from: legacyData(for: url))
            #expect(decoded.modification == nil)

            try Data("rewritten contents".utf8).write(to: url)

            #expect(decoded.modification == .content)
        }

        /// The split form has to survive a JSON round trip exactly: an inexact date makes every
        /// element report a content change on the next scan.
        @Test func splitDatesRoundTripUnchanged() throws {
            let url = try makeFileWithLaterAttributeDate(named: "current.txt")
            let properties = URLProperties(url: url)

            let decoded = try JSONDecoder().decode(
                URLProperties.self,
                from: JSONEncoder().encode(properties)
            )

            #expect(decoded.modificationState == properties.modificationState)
            #expect(decoded.modificationState.isClassifiable)
            #expect(decoded.modification == nil)
        }
    }
#endif
