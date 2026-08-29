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

        // MARK: - Lock state

        @Test func lockStateIsReadFromTheFileAndRoundTrips() throws {
            let url = bin.appendingPathComponent("locked.txt")
            try Data("content".utf8).write(to: url)
            defer { try? url.unlock() }

            try url.lock()

            let properties = URLProperties(url: url)
            #expect(properties.lockState == .locked)

            let decoded = try JSONDecoder().decode(
                URLProperties.self,
                from: JSONEncoder().encode(properties)
            )

            #expect(decoded.lockState == .locked)
        }

        /// The app writes the lock itself, so the record has to absorb the date that write moved --
        /// otherwise the element claims a date the file no longer has, and the next observer scan
        /// reports the app's own change as an external one. For a row also holding an unsaved
        /// colour that becomes a false conflict, since a pending Finder tag edit conflicts rather
        /// than refreshes.
        @Test func refreshingTheLockAbsorbsTheDateTheWriteMoved() throws {
            let url = bin.appendingPathComponent("refreshed.txt")
            try Data("content".utf8).write(to: url)
            defer { try? url.unlock() }

            var properties = URLProperties(url: url)
            #expect(properties.modification == nil)

            try url.lock()

            // The flag alone is what a narrower refresh would update.
            properties.refreshLockState()

            #expect(properties.lockState == .locked)
            #expect(properties.modification == nil, "the app's own lock must not read back as an external change")
        }

        /// A record written before the field existed carries no key, and `.writable` is what that
        /// means: nothing was known to be in the way.
        @Test func aLegacyRecordDecodesAsWritable() throws {
            let url = try makeFileWithLaterAttributeDate(named: "legacy-lock.txt")

            let decoded = try JSONDecoder().decode(URLProperties.self, from: legacyData(for: url))

            #expect(decoded.lockState == .writable)
        }
    }
#endif
