// Copyright Ryan Francesconi. All Rights Reserved.

#if os(macOS)
import Foundation
import os
import SPFKBase
import SPFKFileSystem
import SPFKTesting
import Testing

@testable import SPFKUtils

/// The plan a folder template makes of a selection, against listings held in memory. Folders the
/// builder lists on its own are read from a dictionary standing in for the disk, and counted.
@Suite(.tags(.renameOrganize))
struct MovePlanBuilderFolderTests {
    /// The paths read, relative to the root.
    final class ReadLog: Sendable {
        private let lock = OSAllocatedUnfairLock<[String]>(initialState: [])

        func record(_ path: String) {
            lock.withLock { $0.append(path) }
        }

        var reads: [String] {
            lock.withLock { $0 }
        }
    }

    private let root = URL(fileURLWithPath: "/MovePlanBuilderFolderTests-\(UUID().uuidString)", isDirectory: true)

    private var moveRoot: MoveRoot {
        MoveRoot(url: root, volume: nil, isCaseSensitive: false)
    }

    private func url(_ path: String) -> URL {
        root.appendingPathComponent(path)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> NameTemplate.Value {
        .date(NameTemplate.DateParts(year: year, month: month, day: day))
    }

    private func input(_ path: String, _ values: [String: NameTemplate.Value] = [:], size: UInt64? = nil) -> MovePlanInput {
        var input = MovePlanInput(url: url(path), values: NameTemplate.urlValues(for: url(path)).merging(values) { $1 })
        input.fileSize = size
        return input
    }

    /// Each input's folder listed with the inputs and companions in it; any other folder is read from
    /// `disk`, keyed by its path under the root.
    private func builder(
        _ inputs: [MovePlanInput],
        companions: [URL: [URL]] = [:],
        disk: [String: [String]] = [:],
        reads: ReadLog = ReadLog()
    ) -> MovePlanBuilder {
        var folders: [URL: [String]] = [:]

        for file in inputs.map(\.url) + companions.values.joined() {
            folders[file.deletingLastPathComponent(), default: []].append(file.lastPathComponent)
        }

        let rootPath = root.path

        let listing = FolderListing(folders: folders, caseSensitive: false) { folder in
            let relative = String(folder.standardizedFileURL.path.dropFirst(rootPath.count))
            reads.record(relative)
            return disk[relative]
        }

        return MovePlanBuilder(inputs: inputs, companions: companions, listing: listing)
    }

    private func placement(_ folder: String) -> FolderPlacement {
        .template(NameTemplate(folder), root: moveRoot)
    }

    /// Each moved file's source name → its destination under the root.
    private func destinations(_ plan: MovePlan) -> [String: String] {
        Dictionary(uniqueKeysWithValues: plan.groups.map {
            ($0.source.lastPathComponent, String($0.destination.path.dropFirst(root.path.count + 1)))
        })
    }

    // MARK: - Folders

    @Test func datedFilesLandInYearAndDateFoldersUnderTheRoot() {
        var builder = builder([input("dump/a.jpg", ["date": date(2024, 5, 1)]), input("dump/b.jpg", ["date": date(2023, 12, 31)])])

        let plan = builder.plan(template: NameTemplate("{name}"), placement: placement("{date:YYYY}/{date:YYYY-MM-DD}"))

        #expect(destinations(plan) == ["a.jpg": "2024/2024-05-01/a.jpg", "b.jpg": "2023/2023-12-31/b.jpg"])
    }

    @Test func anUndatedFileTakesTheFallbackAndAnEmptyLevelIsDropped() {
        var builder = builder([
            input("dump/a.jpg"),
            input("dump/b.jpg", ["date": date(2024, 5, 1), "field:Camera": .text("X100")]),
        ])

        let plan = builder.plan(template: NameTemplate("{name}"), placement: placement("{date:YYYY?\"Undated\"}/{field:Camera}"))

        #expect(destinations(plan) == ["a.jpg": "Undated/a.jpg", "b.jpg": "2024/X100/b.jpg"])
    }

    /// A file whose levels all render empty goes in the root itself.
    @Test func albumLevelsRenderFromValuesAndAFileInNoAlbumSkipsThem() {
        var builder = builder([
            input("dump/a.jpg", ["album": .text("Tasmania"), "albumGroup": .text("Trips")]),
            input("dump/b.jpg"),
        ])

        let plan = builder.plan(template: NameTemplate("{name}"), placement: placement("{albumGroup}/{album}"))

        #expect(destinations(plan) == ["a.jpg": "Trips/Tasmania/a.jpg", "b.jpg": "b.jpg"])
    }

    @Test func companionsMoveIntoTheOwnersFolderUnderItsNewBase() throws {
        let photo = input("dump/IMG_1234.HEIC", ["date": date(2024, 5, 1)])
        let companions = [photo.url: [url("dump/IMG_1234.xmp"), url("dump/IMG_1234.aae"), url("dump/IMG_O1234.aae")]]
        var builder = builder([photo], companions: companions)

        let plan = builder.plan(template: NameTemplate("Trip"), placement: placement("{date:YYYY}"))

        let group = try #require(plan.groups.first)
        #expect(group.destination == url("2024/Trip.HEIC"))
        #expect(Set(group.companions.map(\.to)) == [url("2024/Trip.xmp"), url("2024/Trip.aae"), url("2024/Trip_O.aae")])
    }

    // MARK: - Sequence (D5)

    @Test func theSequenceCountsPerDestinationFolder() {
        let days = [1, 2, 1, 2, 1, 2]
        var builder = builder(days.enumerated().map { input("dump/\($0).jpg", ["date": date(2024, 5, $1)]) })

        let plan = builder.plan(template: NameTemplate("Trip_{seq}"), placement: placement("{date:YYYY-MM-DD}"))

        #expect(destinations(plan) == [
            "0.jpg": "2024-05-01/Trip_1.jpg", "2.jpg": "2024-05-01/Trip_2.jpg", "4.jpg": "2024-05-01/Trip_3.jpg",
            "1.jpg": "2024-05-02/Trip_1.jpg", "3.jpg": "2024-05-02/Trip_2.jpg", "5.jpg": "2024-05-02/Trip_3.jpg",
        ])
    }

    @Test func theSequenceCountsTheRunInTheFolderPartAndUnderKeepCurrent() {
        var builder = builder([input("a/1.jpg"), input("b/2.jpg"), input("a/3.jpg")])

        let kept = builder.plan(template: NameTemplate("Trip_{seq}"))
        let filed = builder.plan(template: NameTemplate("{name}"), placement: placement("Set {seq}"))

        #expect(destinations(kept) == ["1.jpg": "a/Trip_1.jpg", "2.jpg": "b/Trip_2.jpg", "3.jpg": "a/Trip_3.jpg"])
        #expect(destinations(filed) == ["1.jpg": "Set 1/1.jpg", "2.jpg": "Set 2/2.jpg", "3.jpg": "Set 3/3.jpg"])
    }

    // MARK: - Identity and claims

    /// Running the same placement again is one-shot: nothing moves, including a folder whose case
    /// differs from the rendered one on a case-insensitive volume.
    @Test func organizingASecondTimeLeavesEverythingInPlace() {
        let inputs = [
            input("2024/2024-05-01/a.jpg", ["date": date(2024, 5, 1)]),
            input("undated/b.jpg"),
        ]
        var builder = builder(inputs)

        let plan = builder.plan(template: NameTemplate("{name}"), placement: placement("{date:YYYY?\"Undated\"}/{date:YYYY-MM-DD}"))

        #expect(plan.entries == inputs.map { .alreadyInPlace($0.url) })
    }

    @Test func aSwapAcrossFoldersNumbersNothing() {
        var builder = builder([input("a/x.jpg", ["to": .text("b")]), input("b/x.jpg", ["to": .text("a")])])

        let preview = builder.preview(template: NameTemplate("{name}"), placement: placement("{to}"))

        #expect(preview.plan.groups.map(\.destination) == [url("b/x.jpg"), url("a/x.jpg")])
        #expect(preview.numbered.isEmpty)
    }

    @Test func twoFilesTakingOneNameInOneFolderAreNumbered() {
        var builder = builder([input("a/x.jpg", ["date": date(2024, 5, 1)]), input("b/x.jpg", ["date": date(2024, 5, 1)])])

        let plan = builder.plan(template: NameTemplate("{name}"), placement: placement("{date:YYYY}"))

        #expect(plan.groups.map(\.destination) == [url("2024/x.jpg"), url("2024/x 1.jpg")])
    }

    /// Two levels differing only in case are one folder on a case-insensitive volume, so their files
    /// number against each other and share the first spelling.
    @Test func foldersDifferingOnlyInCaseAreOneFolder() {
        var builder = builder([input("a/x.jpg", ["make": .text("Canon")]), input("b/x.jpg", ["make": .text("canon")])])

        let plan = builder.plan(template: NameTemplate("{name}"), placement: placement("{make}"))

        #expect(plan.groups.map(\.destination) == [url("Canon/x.jpg"), url("Canon/x 1.jpg")])
    }

    /// Each level takes the spelling an earlier unit gave it, so both models share one make folder.
    @Test func aParentLevelDifferingOnlyInCaseIsOneFolder() {
        var builder = builder([
            input("a/x.jpg", ["make": .text("Canon"), "model": .text("R5")]),
            input("b/y.jpg", ["make": .text("canon"), "model": .text("R6")]),
        ])

        let plan = builder.plan(template: NameTemplate("{name}"), placement: placement("{make}/{model}"))

        #expect(plan.groups.map(\.destination) == [url("Canon/R5/x.jpg"), url("Canon/R6/y.jpg")])
    }

    /// A folder on disk holding no source file still spells the level.
    @Test func aLevelTakesTheSpellingOfAFolderOnDisk() {
        var builder = builder([input("a/x.jpg", ["make": .text("Canon")])], disk: ["": ["a", "canon"], "/canon": []])

        let plan = builder.plan(template: NameTemplate("{name}"), placement: placement("{make}"))

        #expect(plan.groups.map(\.destination) == [url("canon/x.jpg")])
    }

    // MARK: - Volumes

    @Test func aFileOnAnotherVolumeStaysUnderAFolderPlacementOnly() {
        let disk = URL(fileURLWithPath: "/Volumes/Disk", isDirectory: true)
        let boot = MoveRoot(url: root, volume: URL(fileURLWithPath: "/", isDirectory: true), isCaseSensitive: false)
        var away = input("dump/x.jpg")
        away.volume = disk
        var builder = builder([away, input("dump/y.jpg")])

        let filed = builder.plan(template: NameTemplate("{name}"), placement: .template(NameTemplate("a"), root: boot))
        let renamed = builder.plan(template: NameTemplate("Trip"))

        #expect(filed.entries.first == .skipped(away.url, .otherVolume))
        #expect(destinations(filed) == ["y.jpg": "a/y.jpg"])
        #expect(destinations(renamed) == ["x.jpg": "dump/Trip.jpg", "y.jpg": "dump/Trip 1.jpg"])
    }

    // MARK: - Duplicates (D16)

    private func pair(_ first: String, _ second: String) -> DuplicateVerdicts.Pair {
        DuplicateVerdicts.Pair(first: url(first), second: url(second))
    }

    private func verdicts(_ identical: Bool, _ first: String, _ second: String) -> DuplicateVerdicts {
        var verdicts = DuplicateVerdicts()
        verdicts.record(identical, for: pair(first, second))
        return verdicts
    }

    /// Two files of equal size dated one day, so both render `2024/x.jpg`.
    private var twoCandidates: [MovePlanInput] {
        [input("a/x.jpg", ["date": date(2024, 5, 1)], size: 10), input("b/x.jpg", ["date": date(2024, 5, 1)], size: 10)]
    }

    @Test func anIdenticalSecondSourceStaysWhereItIs() {
        var builder = builder(twoCandidates)

        let preview = builder.preview(template: NameTemplate("{name}"), placement: placement("{date:YYYY}"), duplicates: verdicts(true, "a/x.jpg", "b/x.jpg"))

        #expect(preview.plan.entries == [
            .move(MovePlan.Group(source: url("a/x.jpg"), destination: url("2024/x.jpg"))),
            .skipped(url("b/x.jpg"), .duplicate(of: url("a/x.jpg"))),
        ])
        #expect(preview.unresolved.isEmpty)
    }

    @Test func aDifferentSecondSourceIsNumbered() {
        var builder = builder(twoCandidates)

        let preview = builder.preview(template: NameTemplate("{name}"), placement: placement("{date:YYYY}"), duplicates: verdicts(false, "a/x.jpg", "b/x.jpg"))

        #expect(preview.plan.groups.map(\.destination) == [url("2024/x.jpg"), url("2024/x 1.jpg")])
        #expect(preview.unresolved.isEmpty)
    }

    @Test func aPairNotComparedYetIsNumberedAndReported() {
        var builder = builder(twoCandidates)

        let preview = builder.preview(template: NameTemplate("{name}"), placement: placement("{date:YYYY}"))

        #expect(preview.plan.groups.map(\.destination) == [url("2024/x.jpg"), url("2024/x 1.jpg")])
        #expect(preview.unresolved == [pair("a/x.jpg", "b/x.jpg")])
    }

    @Test func filesOfDifferentSizesAreNeverCandidates() {
        var builder = builder([input("a/x.jpg", ["date": date(2024, 5, 1)], size: 10), input("b/x.jpg", ["date": date(2024, 5, 1)], size: 11)])

        let preview = builder.preview(template: NameTemplate("{name}"), placement: placement("{date:YYYY}"))

        #expect(preview.plan.groups.count == 2)
        #expect(preview.unresolved.isEmpty)
    }

    @Test func aDuplicatesCompanionsStayWithIt() {
        let inputs = twoCandidates
        let companions = [inputs[1].url: [url("b/x.xmp")]]
        var builder = builder(inputs, companions: companions)

        let plan = builder.plan(template: NameTemplate("{name}"), placement: placement("{date:YYYY}"), duplicates: verdicts(true, "a/x.jpg", "b/x.jpg"))

        #expect(plan.groups.map(\.source) == [url("a/x.jpg")])
        #expect(plan.groups.flatMap(\.companions).isEmpty)
    }

    /// Only sources of the run are compared: a file already at the destination outside it numbers
    /// the incoming file, however alike they are.
    @Test func aDestinationHeldOutsideTheRunIsNeverACandidate() {
        var builder = builder([input("a/x.jpg", ["date": date(2024, 5, 1)], size: 10)], disk: ["": ["a", "2024"], "/2024": ["x.jpg"]])

        let preview = builder.preview(template: NameTemplate("{name}"), placement: placement("{date:YYYY}"))

        #expect(destinations(preview.plan) == ["x.jpg": "2024/x 1.jpg"])
        #expect(preview.unresolved.isEmpty)
    }

    /// A source already in place holds its name for the rest, wherever it falls in display order.
    @Test func aSourceAlreadyInPlaceIsCompared() {
        let inputs = [input("dump/x.jpg", ["date": date(2024, 5, 1)], size: 10), input("2024/x.jpg", ["date": date(2024, 5, 1)], size: 10)]
        var builder = builder(inputs)

        let preview = builder.preview(template: NameTemplate("{name}"), placement: placement("{date:YYYY}"), duplicates: verdicts(true, "2024/x.jpg", "dump/x.jpg"))

        #expect(preview.plan.entries == [.skipped(url("dump/x.jpg"), .duplicate(of: url("2024/x.jpg"))), .alreadyInPlace(url("2024/x.jpg"))])
    }

    @Test func keepCurrentFolderNeverComparesFiles() {
        var builder = builder([input("a/1.jpg", size: 10), input("a/2.jpg", size: 10)])

        let preview = builder.preview(template: NameTemplate("Trip"))

        #expect(preview.plan.groups.map(\.destination) == [url("a/Trip.jpg"), url("a/Trip 1.jpg")])
        #expect(preview.unresolved.isEmpty)
    }

    // MARK: - Destination listings

    @Test func aNameHeldInTheDestinationByAFileOutsideTheRunNumbersTheIncomingFile() {
        var builder = builder([input("dump/x.jpg", ["date": date(2024, 5, 1)])], disk: ["": ["dump", "2024"], "/2024": ["x.jpg"]])

        let plan = builder.plan(template: NameTemplate("{name}"), placement: placement("{date:YYYY}"))

        #expect(destinations(plan) == ["x.jpg": "2024/x 1.jpg"])
    }

    /// The root is read once, which answers for every folder it does not hold, and a later preview
    /// reads nothing.
    @Test func eachDestinationFolderIsListedOnceAcrossPreviews() {
        let reads = ReadLog()
        let inputs = (1 ... 20).map { input("dump/\($0).jpg", ["date": date(2024, 5, $0)]) }
        var builder = builder(inputs, disk: ["": ["dump", "2024"], "/2024": ["2024-05-01"], "/2024/2024-05-01": []], reads: reads)
        let folders = placement("{date:YYYY}/{date:YYYY-MM-DD}")

        _ = builder.preview(template: NameTemplate("{name}"), placement: folders)
        let first = reads.reads
        _ = builder.preview(template: NameTemplate("Trip_{seq}"), placement: folders)

        #expect(first.sorted() == ["", "/2024", "/2024/2024-05-01"])
        #expect(reads.reads == first)
    }
}
#endif
