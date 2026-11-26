// Copyright Ryan Francesconi. All Rights Reserved.

#if os(macOS)
import Foundation
import SPFKBase
import SPFKFileSystem
import SPFKTesting
import Testing

@testable import SPFKUtils

/// The bytes a copy writes on each volume it writes to, against that volume's free space.
@Suite(.tags(.renameOrganize))
struct CopySpaceTests {
    private let base = URL(fileURLWithPath: "/CopySpaceTests-\(UUID().uuidString)", isDirectory: true)
    private let here = URL(fileURLWithPath: "/", isDirectory: true)
    private let there = URL(fileURLWithPath: "/Volumes/Other", isDirectory: true)

    private func input(_ path: String, size: UInt64?, volume: URL?) -> MovePlanInput {
        let url = base.appendingPathComponent(path)
        var input = MovePlanInput(url: url, values: NameTemplate.urlValues(for: url))
        input.fileSize = size
        input.volume = volume
        return input
    }

    private func builder(_ inputs: [MovePlanInput]) -> MovePlanBuilder {
        var folders: [URL: [String]] = [:]

        for url in inputs.map(\.url) {
            folders[url.deletingLastPathComponent(), default: []].append(url.lastPathComponent)
        }

        return MovePlanBuilder(inputs: inputs, companions: [:], listing: FolderListing(folders: folders, caseSensitive: false) { _ in [] })
    }

    /// Beside each source: a volume that clones needs nothing; one that does not needs its own
    /// files' sizes, checked against its own free space.
    @Test func keepingTheFolderNeedsSpaceOnEachSourceVolumeThatCannotClone() {
        var builder = builder([
            input("a/near.jpg", size: 10, volume: here),
            input("b/far.jpg", size: 20, volume: there),
            input("b/far2.jpg", size: 30, volume: there),
        ])
        let plan = builder.preview(template: NameTemplate("{name}"), operation: .copy).plan

        let needs = builder.copySpaceNeeds(plan, placement: .keepCurrent) { folder in
            folder.path.hasPrefix(base.appendingPathComponent("a").path)
                ? VolumeSpace(availableCapacity: 1, supportsCloning: true, name: "Here")
                : VolumeSpace(availableCapacity: 40, supportsCloning: false, name: "Other")
        }

        #expect(needs == [CopySpaceNeed(bytes: 50, availableCapacity: 40, volumeName: "Other")])
        #expect(needs.first?.isShort == true)
        #expect(builder.totalBytes(of: plan) == 60)
    }

    /// Under a root, its own volume's space, read when the root was chosen.
    @Test func aRootNeedsTheFilesItCannotClone() {
        var builder = builder([input("a/near.jpg", size: 10, volume: here), input("a/far.jpg", size: 20, volume: there)])
        let root = MoveRoot(url: base, volume: here, isCaseSensitive: false, availableCapacity: 100, supportsCloning: true, volumeName: "Here")
        let placement = FolderPlacement.template(NameTemplate("Out"), root: root)
        let plan = builder.preview(template: NameTemplate("{name}"), placement: placement, operation: .copy).plan

        let needs = builder.copySpaceNeeds(plan, placement: placement) { _ in
            Issue.record("a root's volume is not read again")
            return VolumeSpace(availableCapacity: nil, supportsCloning: false, name: nil)
        }

        #expect(needs == [CopySpaceNeed(bytes: 20, availableCapacity: 100, volumeName: "Here")])
        #expect(needs.first?.isShort == false)
    }

    @Test func aVolumeOfUnreadSpaceIsNeverShort() {
        #expect(!CopySpaceNeed(bytes: 1 << 40, availableCapacity: nil, volumeName: nil).isShort)
        #expect(CopySpaceNeed(bytes: 11, availableCapacity: 10, volumeName: nil).isShort)
        #expect(!CopySpaceNeed(bytes: 10, availableCapacity: 10, volumeName: nil).isShort)
    }

    /// External APFS and HFS+ volumes answer important-usage capacity with 0, not nil
    /// (measured: a USB APFS disk with 335 GB free read 0).
    @Test func freeSpaceIsTheLargerOfTheTwoAnswers() {
        #expect(VolumeSpace.availableCapacity(importantUsage: 0, available: 360_080_781_312) == 360_080_781_312)
        #expect(VolumeSpace.availableCapacity(importantUsage: 237_160_223_721, available: 193_807_314_944) == 237_160_223_721)
        #expect(VolumeSpace.availableCapacity(importantUsage: nil, available: 6_553_600) == 6_553_600)
        #expect(VolumeSpace.availableCapacity(importantUsage: 5, available: nil) == 5)
        #expect(VolumeSpace.availableCapacity(importantUsage: nil, available: nil) == nil)
    }

    @Test func aFolderReadsItsVolumesSpace() {
        let space = VolumeSpace.read(at: FileManager.default.temporaryDirectory)

        #expect(space.availableCapacity.map { $0 > 0 } == true)
        #expect(space.name?.isEmpty == false)
    }
}
#endif
