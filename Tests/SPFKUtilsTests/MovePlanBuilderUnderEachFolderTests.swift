// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import SPFKBase
import SPFKFileSystem
import SPFKTesting
import Testing

@testable import SPFKUtils

/// ``FolderPlacement/underEachFolder(_:)``: each file's levels built under its own folder, where a
/// folder already ending in a leading run of them takes the rest only.
@Suite(.tags(.renameOrganize))
struct MovePlanBuilderUnderEachFolderTests {
    // MARK: - The base folder

    private let levels = ["2019", "2019-02-15"]

    @Test(arguments: [
        ("/A", "/A"),
        ("/A/2019", "/A"),
        ("/A/2019/2019-02-15", "/A"),
        ("/A/2019-02-15", "/A/2019-02-15"),
        ("/A/2019/Other", "/A/2019/Other"),
        ("/2019", "/"),
    ])
    func theBaseDropsTheLeadingRunOfLevelsTheFolderEndsIn(path: String, base: String) {
        #expect(MovePlanBuilder.baseFolder(path: path, levels: levels, isCaseSensitive: false) == base)
    }

    @Test func theBaseComparesByTheFoldersCaseRule() {
        #expect(MovePlanBuilder.baseFolder(path: "/A/undated", levels: ["Undated"], isCaseSensitive: false) == "/A")
        #expect(MovePlanBuilder.baseFolder(path: "/A/undated", levels: ["Undated"], isCaseSensitive: true) == "/A/undated")
    }

    @Test func noLevelsLeaveTheFolderItself() {
        #expect(MovePlanBuilder.baseFolder(path: "/A/2019", levels: [], isCaseSensitive: false) == "/A/2019")
    }

    // MARK: - Plans

    private let root = URL(fileURLWithPath: "/MovePlanBuilderUnderEachFolderTests-\(UUID().uuidString)", isDirectory: true)

    private func url(_ path: String) -> URL {
        root.appendingPathComponent(path)
    }

    private let feb15 = NameTemplate.Value.date(NameTemplate.DateParts(year: 2019, month: 2, day: 15))

    private func input(_ path: String, size: UInt64? = nil) -> MovePlanInput {
        var input = MovePlanInput(url: url(path), values: NameTemplate.urlValues(for: url(path)).merging(["date": feb15]) { $1 })
        input.fileSize = size
        return input
    }

    /// Each input's folder listed with the inputs in it, and with what `disk` adds to it; any other
    /// folder is read from `disk`, keyed by its path under the root.
    private func builder(_ inputs: [MovePlanInput], disk: [String: [String]] = [:]) -> MovePlanBuilder {
        var folders: [URL: [String]] = [:]

        for file in inputs.map(\.url) {
            folders[file.deletingLastPathComponent(), default: []].append(file.lastPathComponent)
        }

        for folder in folders.keys {
            folders[folder]? += disk[String(folder.standardizedFileURL.path.dropFirst(root.path.count))] ?? []
        }

        let rootPath = root.path

        let listing = FolderListing(folders: folders, caseSensitive: false) { folder in
            disk[String(folder.standardizedFileURL.path.dropFirst(rootPath.count))]
        }

        return MovePlanBuilder(inputs: inputs, companions: [:], listing: listing)
    }

    private let yearDate = FolderPlacement.underEachFolder(NameTemplate("{date:YYYY}/{date:YYYY-MM-DD}"))

    /// Each moved file's path under the root → its destination under the root.
    private func destinations(_ plan: MovePlan) -> [String: String] {
        let count = root.path.count + 1
        return Dictionary(uniqueKeysWithValues: plan.groups.map {
            (String($0.source.path.dropFirst(count)), String($0.destination.path.dropFirst(count)))
        })
    }

    @Test func filesFromTwoFoldersAreFiledUnderTheirOwn() {
        var builder = builder([input("A/x.wav"), input("B/y.wav")])

        let plan = builder.plan(template: NameTemplate("{name}"), placement: yearDate)

        #expect(destinations(plan) == ["A/x.wav": "A/2019/2019-02-15/x.wav", "B/y.wav": "B/2019/2019-02-15/y.wav"])
    }

    @Test func aSecondRunLeavesEveryFileInPlace() {
        let inputs = [input("A/2019/2019-02-15/x.wav"), input("B/2019/2019-02-15/y.wav")]
        var builder = builder(inputs)

        let preview = builder.preview(template: NameTemplate("{name}"), placement: yearDate)

        #expect(preview.plan.entries == inputs.map { .alreadyInPlace($0.url) })
    }

    @Test func aFolderPartwayThereIsCompleted() {
        var builder = builder([input("A/2019/x.wav"), input("A/2019-02-15/y.wav")])

        let plan = builder.plan(template: NameTemplate("{name}"), placement: yearDate)

        #expect(destinations(plan) == [
            "A/2019/x.wav": "A/2019/2019-02-15/x.wav",
            "A/2019-02-15/y.wav": "A/2019-02-15/2019/2019-02-15/y.wav",
        ])
    }

    @Test func theSequenceCountsPerDestinationFolder() {
        var builder = builder([input("A/1.wav"), input("B/2.wav"), input("A/3.wav")])

        let plan = builder.plan(template: NameTemplate("Take_{seq}"), placement: yearDate)

        #expect(destinations(plan) == [
            "A/1.wav": "A/2019/2019-02-15/Take_1.wav",
            "B/2.wav": "B/2019/2019-02-15/Take_1.wav",
            "A/3.wav": "A/2019/2019-02-15/Take_2.wav",
        ])
    }

    @Test func anIdenticalFileFiledIntoTheSameFolderStaysWhereItIs() {
        var builder = builder([input("A/x.wav", size: 10), input("A/2019/x.wav", size: 10)])
        var verdicts = DuplicateVerdicts()
        verdicts.record(true, for: DuplicateVerdicts.Pair(first: url("A/x.wav"), second: url("A/2019/x.wav")))

        let plan = builder.preview(template: NameTemplate("{name}"), placement: yearDate, duplicates: verdicts).plan

        #expect(plan.entries == [
            .move(MovePlan.Group(source: url("A/x.wav"), destination: url("A/2019/2019-02-15/x.wav"))),
            .skipped(url("A/2019/x.wav"), .duplicate(of: url("A/x.wav"))),
        ])
    }

    @Test(arguments: [MoveOperation.move, .copy])
    func anUnwritableFolderOrAPackageIsSkipped(operation: MoveOperation) {
        var readOnly = input("cd/a.wav")
        readOnly.isFolderWritable = false
        var packaged = input("lib.bundle/b.wav")
        packaged.isInsidePackage = true
        var elsewhere = input("dump/c.wav")
        elsewhere.volume = URL(fileURLWithPath: "/Volumes/Other", isDirectory: true)

        var builder = builder([readOnly, packaged, elsewhere])
        let plan = builder.preview(template: NameTemplate("{name}"), placement: yearDate, operation: operation).plan

        #expect(plan.entries == [
            .skipped(url("cd/a.wav"), .sourceFolderNotWritable),
            .skipped(url("lib.bundle/b.wav"), .insidePackage),
            .move(MovePlan.Group(source: url("dump/c.wav"), destination: url("dump/2019/2019-02-15/c.wav"))),
        ])
    }

    /// A copy lands in the subfolders and leaves its source, and its space is each source volume's.
    @Test func aCopyIsFiledUnderEachFolderAndNeedsEachSourceVolumesSpace() {
        let here = URL(fileURLWithPath: "/", isDirectory: true)
        let other = URL(fileURLWithPath: "/Volumes/Other", isDirectory: true)
        var near = input("A/x.wav", size: 10)
        near.volume = here
        var far = input("B/y.wav", size: 20)
        far.volume = other

        var builder = builder([near, far])
        let plan = builder.preview(template: NameTemplate("{name}"), placement: yearDate, operation: .copy).plan

        #expect(destinations(plan) == ["A/x.wav": "A/2019/2019-02-15/x.wav", "B/y.wav": "B/2019/2019-02-15/y.wav"])

        let needs = builder.copySpaceNeeds(plan, placement: yearDate) { folder in
            VolumeSpace(availableCapacity: 1000, supportsCloning: false, name: folder.path)
        }

        #expect(needs.map(\.bytes) == [10, 20])
    }

    @Test func aNameTakenInAnExistingSubfolderIsNumbered() {
        var builder = builder([input("A/x.wav")], disk: ["/A": ["2019"], "/A/2019": ["2019-02-15"], "/A/2019/2019-02-15": ["x.wav"]])

        let plan = builder.plan(template: NameTemplate("{name}"), placement: yearDate)

        #expect(destinations(plan) == ["A/x.wav": "A/2019/2019-02-15/x 1.wav"])
    }

    /// A template rendering no level renames the file where it is.
    @Test func noLevelRenamesInPlace() {
        var builder = builder([input("A/x.wav")])

        let plan = builder.plan(template: NameTemplate("Take"), placement: .underEachFolder(NameTemplate("{field:Missing}")))

        #expect(destinations(plan) == ["A/x.wav": "A/Take.wav"])
    }
}
