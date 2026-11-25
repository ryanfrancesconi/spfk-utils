// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import SPFKBase
import SPFKFileSystem
import SPFKTesting
import Testing

@testable import SPFKUtils

/// The plan a template makes of a selection under ``MoveOperation/copy``: every file claims a
/// name, none gives one up, and only what a copy cannot read or write is skipped.
@Suite(.tags(.renameOrganize))
struct MovePlanBuilderCopyTests {
    private let root = URL(fileURLWithPath: "/MovePlanBuilderCopyTests-\(UUID().uuidString)", isDirectory: true)

    private func url(_ path: String) -> URL {
        root.appendingPathComponent(path)
    }

    private func input(_ path: String, _ values: [String: NameTemplate.Value] = [:], size: UInt64? = nil) -> MovePlanInput {
        var input = MovePlanInput(url: url(path), values: NameTemplate.urlValues(for: url(path)).merging(values) { $1 })
        input.fileSize = size
        return input
    }

    /// Each input's folder listed with the inputs and companions in it; every other folder empty.
    private func builder(_ inputs: [MovePlanInput], companions: [URL: [URL]] = [:]) -> MovePlanBuilder {
        var folders: [URL: [String]] = [:]

        for file in inputs.map(\.url) + companions.values.joined() {
            folders[file.deletingLastPathComponent(), default: []].append(file.lastPathComponent)
        }

        return MovePlanBuilder(inputs: inputs, companions: companions, listing: FolderListing(folders: folders, caseSensitive: false) { _ in [] })
    }

    private func placement(_ folder: String, volume: URL? = nil) -> FolderPlacement {
        .template(NameTemplate(folder), root: MoveRoot(url: root, volume: volume, isCaseSensitive: false))
    }

    private func copyPreview(_ builder: inout MovePlanBuilder, _ template: String, placement: FolderPlacement = .keepCurrent, duplicates: DuplicateVerdicts = DuplicateVerdicts()) -> MovePlan {
        builder.preview(template: NameTemplate(template), placement: placement, duplicates: duplicates, operation: .copy).plan
    }

    @Test func keepingTheFolderAndTheNameNumbersEveryFileWithItsCompanions() throws {
        let photo = input("dump/a.jpg")
        var builder = builder([photo, input("dump/b.jpg")], companions: [photo.url: [url("dump/a.xmp")]])

        let plan = copyPreview(&builder, "{name}")

        #expect(plan.groups.map(\.destination) == [url("dump/a 1.jpg"), url("dump/b 1.jpg")])
        #expect(plan.groups.first?.companions == [MovePlan.CompanionMove(from: url("dump/a.xmp"), to: url("dump/a 1.xmp"))])
    }

    /// Under a move, the same template leaves every file where it is.
    @Test func aMoveOfTheSameTemplateIsAlreadyInPlace() {
        var builder = builder([input("dump/a.jpg")])

        #expect(builder.preview(template: NameTemplate("{name}")).plan.entries == [.alreadyInPlace(url("dump/a.jpg"))])
    }

    /// `A→B` while `B→A`: neither gives its name up, so both copies are numbered.
    @Test func aSwapCopiesBothUnderNewNumbers() {
        var builder = builder([input("dump/A.jpg", ["name": .text("B")]), input("dump/B.jpg", ["name": .text("A")])])

        let plan = copyPreview(&builder, "{name}")

        #expect(plan.groups.map(\.destination) == [url("dump/B 1.jpg"), url("dump/A 1.jpg")])
    }

    /// A copy only reads its source, and the root was checked when it was chosen.
    @Test func underAFolderTemplateWhatACopyOnlyReadsIsCopied() {
        var locked = input("dump/locked.jpg")
        locked.isLocked = true
        var readOnly = input("cd/readOnly.jpg")
        readOnly.isFolderWritable = false
        var packaged = input("lib.photoslibrary/packaged.jpg")
        packaged.isInsidePackage = true
        var elsewhere = input("dump/elsewhere.jpg")
        elsewhere.volume = URL(fileURLWithPath: "/Volumes/Other", isDirectory: true)

        var builder = builder([locked, readOnly, packaged, elsewhere])
        let plan = copyPreview(&builder, "{name}", placement: placement("Out", volume: URL(fileURLWithPath: "/", isDirectory: true)))

        #expect(plan.groups.map(\.destination) == [
            url("Out/locked.jpg"), url("Out/readOnly.jpg"), url("Out/packaged.jpg"), url("Out/elsewhere.jpg"),
        ])
    }

    /// Beside the source, its own folder is the destination.
    @Test func keepingTheFolderSkipsAnUnwritableFolderAndAPackageButCopiesALockedFile() {
        var locked = input("dump/locked.jpg")
        locked.isLocked = true
        var readOnly = input("cd/readOnly.jpg")
        readOnly.isFolderWritable = false
        var packaged = input("lib.photoslibrary/packaged.jpg")
        packaged.isInsidePackage = true

        var builder = builder([locked, readOnly, packaged])
        let plan = copyPreview(&builder, "{name}")

        #expect(plan.entries == [
            .move(MovePlan.Group(source: url("dump/locked.jpg"), destination: url("dump/locked 1.jpg"))),
            .skipped(url("cd/readOnly.jpg"), .sourceFolderNotWritable),
            .skipped(url("lib.photoslibrary/packaged.jpg"), .insidePackage),
        ])
    }

    @Test func aMissingOrBusyFileIsSkipped() {
        var missing = input("dump/missing.jpg")
        missing.isMissing = true
        var busy = input("dump/busy.jpg")
        busy.isBusy = true

        var builder = builder([missing, busy])
        let plan = copyPreview(&builder, "{name}", placement: placement("Out"))

        #expect(plan.entries == [.skipped(url("dump/missing.jpg"), .missing), .skipped(url("dump/busy.jpg"), .busy)])
    }

    @Test func twoIdenticalSourcesTakingOneNameCopyOnce() {
        let date = NameTemplate.Value.date(NameTemplate.DateParts(year: 2024, month: 5, day: 1))
        var builder = builder([input("a/x.jpg", ["date": date], size: 10), input("b/x.jpg", ["date": date], size: 10)])
        var verdicts = DuplicateVerdicts()
        verdicts.record(true, for: DuplicateVerdicts.Pair(first: url("a/x.jpg"), second: url("b/x.jpg")))

        let plan = copyPreview(&builder, "{name}", placement: placement("{date:YYYY}"), duplicates: verdicts)

        #expect(plan.entries == [
            .move(MovePlan.Group(source: url("a/x.jpg"), destination: url("2024/x.jpg"))),
            .skipped(url("b/x.jpg"), .duplicate(of: url("a/x.jpg"))),
        ])
    }

    /// A copy gets its row's unsaved edits written on, so it no longer matches the identical file:
    /// both are copied, under either order. A move still leaves the second where it is.
    @Test(arguments: [0, 1])
    func anIdenticalSourceWithUnsavedEditsIsCopiedToo(editedIndex: Int) {
        let date = NameTemplate.Value.date(NameTemplate.DateParts(year: 2024, month: 5, day: 1))
        var inputs = [input("a/x.jpg", ["date": date], size: 10), input("b/x.jpg", ["date": date], size: 10)]
        inputs[editedIndex].hasUnsavedEdits = true
        var verdicts = DuplicateVerdicts()
        verdicts.record(true, for: DuplicateVerdicts.Pair(first: url("a/x.jpg"), second: url("b/x.jpg")))

        var builder = builder(inputs)
        let plan = copyPreview(&builder, "{name}", placement: placement("{date:YYYY}"), duplicates: verdicts)

        #expect(plan.groups.map(\.destination) == [url("2024/x.jpg"), url("2024/x 1.jpg")])

        let moved = builder.preview(template: NameTemplate("{name}"), placement: placement("{date:YYYY}"), duplicates: verdicts).plan
        #expect(moved.entries.last == .skipped(url("b/x.jpg"), .duplicate(of: url("a/x.jpg"))))
    }

    /// Only planned groups count: a skipped file writes nothing.
    @Test func theBytesToCopyCountThePlannedFilesTheRootCannotClone() {
        let here = URL(fileURLWithPath: "/", isDirectory: true)
        var near = input("dump/near.jpg", size: 10)
        near.volume = here
        var far = input("dump/far.jpg", size: 20)
        far.volume = URL(fileURLWithPath: "/Volumes/Other", isDirectory: true)
        var missing = input("dump/missing.jpg", size: 40)
        missing.isMissing = true

        var builder = builder([near, far, missing])
        let root = MoveRoot(url: root, volume: here, isCaseSensitive: false, supportsCloning: true)
        let plan = builder.preview(template: NameTemplate("{name}"), placement: .template(NameTemplate("Out"), root: root), operation: .copy).plan

        #expect(builder.bytesToCopy(plan, root: root) == 20)
    }
}

/// The copy plan's last step asks the disk through the copy's own check.
@Suite(.tags(.file, .renameOrganize), .serialized)
final class MovePlanBuilderCopyDiskTests: BinTestCase {
    /// A move's check refuses a locked source; a copy's does not.
    @Test func aLockedSourcePassesTheCopyCheck() throws {
        let a = bin.appendingPathComponent("a.jpg")
        try Data().write(to: a)
        try a.lock()
        defer { try? a.unlock() }

        var builder = MovePlanBuilder(
            inputs: [MovePlanInput(url: a, values: NameTemplate.urlValues(for: a), isLocked: true)],
            companions: [:],
            listing: FolderListing.reading([bin])
        )

        let plan = builder.plan(template: NameTemplate("{name}"), operation: .copy)

        #expect(plan.groups.map(\.destination.lastPathComponent) == ["a 1.jpg"])
        #expect(FileCommands.copyConflicts(in: plan).isEmpty)
    }

    @Test func aNameTheListingMissedIsNumberedAround() throws {
        let a = bin.appendingPathComponent("a.jpg")
        try Data().write(to: a)

        let stale = FolderListing.reading([bin])
        try Data().write(to: bin.appendingPathComponent("a 1.jpg"))

        var builder = MovePlanBuilder(inputs: [MovePlanInput(url: a, values: NameTemplate.urlValues(for: a))], companions: [:], listing: stale)
        let plan = builder.plan(template: NameTemplate("{name}"), operation: .copy)

        #expect(plan.groups.map(\.destination.lastPathComponent) == ["a 2.jpg"])
    }
}
