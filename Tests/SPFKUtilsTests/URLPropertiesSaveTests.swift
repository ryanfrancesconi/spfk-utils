// Copyright Ryan Francesconi. All Rights Reserved.

#if os(macOS)
    import Foundation
    import SPFKBase
    import SPFKFileSystem
    import SPFKTesting
    import Testing

    @testable import SPFKUtils

    /// Re-pointing at another file, and the end of a metadata save.
    @Suite(.tags(.file))
    final class URLPropertiesSaveTests: BinTestCase {
        private func makeFile(named name: String, bytes: Int) throws -> URL {
            let url = bin.appendingPathComponent(name)
            try Data(repeating: 0x41, count: bytes).write(to: url)
            return url
        }

        /// An unsaved Finder tag edit travels; everything else is the new file's.
        @Test func repointedKeepsTheFinderTagsAndReadsTheRestFromTheNewFile() throws {
            deleteBinOnExit = true
            let source = try makeFile(named: "source.txt", bytes: 1)
            let copy = try makeFile(named: "copy.txt", bytes: 3)
            try copy.set(finderTags: FinderTagGroup(tags: [FinderTagDescription(tagColor: .green)]))

            var properties = URLProperties(url: source)
            properties.finderTags = FinderTagGroup(tags: [FinderTagDescription(tagColor: .red)])

            let repointed = properties.repointed(to: copy)
            let fresh = URLProperties(url: copy)

            #expect(repointed.url == copy)
            #expect(repointed.finderTags == properties.finderTags)
            #expect(repointed.fileSize == 3)
            #expect(repointed.modificationState == fresh.modificationState)
            #expect(repointed.lockState == fresh.lockState)
            #expect(repointed.creationDate == fresh.creationDate)
        }

        /// The tags reach the file, and the recorded dates are the ones the write produced, so the
        /// next scan does not report the save as an external change.
        @Test func finishSaveWritesTheFinderTagsAndRecordsTheNewDates() throws {
            deleteBinOnExit = true
            let url = try makeFile(named: "saved.txt", bytes: 1)
            let past = Date(timeIntervalSinceNow: -3600)
            try FileManager.default.setAttributes([.modificationDate: past], ofItemAtPath: url.path)

            var properties = URLProperties(url: url)
            properties.finderTags = FinderTagGroup(tags: [FinderTagDescription(tagColor: .red)])

            try properties.finishSave(at: url)

            #expect(FinderTagGroup(url: url) == properties.finderTags)
            #expect((properties.modificationDate ?? past) > past)
            #expect(properties.isModified == false)
        }

        /// A store that found a moved file updates the element's URL and not its properties; the
        /// save writes to where the file is, and the record follows it.
        @Test func finishSaveWritesToTheFilesCurrentLocation() throws {
            deleteBinOnExit = true
            let old = try makeFile(named: "old.txt", bytes: 1)
            var properties = URLProperties(url: old)
            properties.finderTags = FinderTagGroup(tags: [FinderTagDescription(tagColor: .blue)])

            let moved = bin.appendingPathComponent("moved.txt")
            try FileManager.default.moveItem(at: old, to: moved)

            try properties.finishSave(at: moved)

            #expect(properties.url == moved)
            #expect(FinderTagGroup(url: moved) == properties.finderTags)
        }
    }
#endif
