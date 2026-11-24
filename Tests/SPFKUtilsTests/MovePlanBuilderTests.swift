// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import SPFKBase
import SPFKFileSystem
import SPFKTesting
import Testing

@testable import SPFKUtils

/// The plan a template makes of a selection, against folder listings held in memory.
@Suite(.tags(.renameOrganize))
struct MovePlanBuilderTests {
    private let folder = URL(fileURLWithPath: "/MovePlanBuilderTests-\(UUID().uuidString)", isDirectory: true)

    private func url(_ name: String) -> URL {
        folder.appendingPathComponent(name)
    }

    private func input(_ name: String, isLocked: Bool = false, isBusy: Bool = false, isMissing: Bool = false) -> MovePlanInput {
        MovePlanInput(url: url(name), values: NameTemplate.urlValues(for: url(name)), isLocked: isLocked, isBusy: isBusy, isMissing: isMissing)
    }

    /// The folder holding `names`, plus each input's own file.
    private func listing(_ names: [String], inputs: [MovePlanInput] = [], caseSensitive: Bool = false) -> FolderListing {
        FolderListing(folders: [folder: names + inputs.map(\.url.lastPathComponent)], caseSensitive: caseSensitive)
    }

    private func build(
        _ inputs: [MovePlanInput],
        _ template: String,
        companions: [URL: [URL]] = [:],
        others: [String] = [],
        caseSensitive: Bool = false
    ) -> MovePlan {
        let companionNames = companions.values.flatMap { $0.map(\.lastPathComponent) }

        return MovePlanBuilder.build(
            inputs: inputs,
            companions: companions,
            template: NameTemplate(template),
            listing: listing(others + companionNames, inputs: inputs, caseSensitive: caseSensitive)
        )
    }

    private func destinations(_ plan: MovePlan) -> [String: String] {
        Dictionary(uniqueKeysWithValues: plan.groups.map { ($0.source.lastPathComponent, $0.destination.lastPathComponent) })
    }

    // MARK: - Sequence

    @Test func theSequenceFollowsInputOrderAndSkipsTakeNoNumber() {
        let plan = build([input("c.jpg"), input("a.jpg", isLocked: true), input("b.jpg")], "Trip_{seq:3}")

        #expect(destinations(plan) == ["c.jpg": "Trip_001.jpg", "b.jpg": "Trip_002.jpg"])
        #expect(plan.entries.map(\.source.lastPathComponent) == ["c.jpg", "a.jpg", "b.jpg"])
        #expect(plan.entries[1] == .skipped(url("a.jpg"), .locked))
    }

    // MARK: - RAW + JPEG (D6)

    @Test func aSelectedRAWAndJPEGTakeOneBaseAndOneNumber() {
        let plan = build([input("DSCF1.RAF"), input("DSCF1.JPG"), input("DSCF2.JPG")], "Trip_{seq:3}")

        #expect(destinations(plan) == ["DSCF1.RAF": "Trip_001.RAF", "DSCF1.JPG": "Trip_001.JPG", "DSCF2.JPG": "Trip_002.JPG"])
    }

    @Test func aRAWWhosePartnerIsNotSelectedIsRenamedAlone() {
        let plan = build([input("DSCF1.RAF"), input("DSCF2.JPG")], "Trip_{seq:3}", others: ["DSCF1.JPG"])

        #expect(destinations(plan) == ["DSCF1.RAF": "Trip_001.RAF", "DSCF2.JPG": "Trip_002.JPG"])
    }

    // MARK: - Identity and claims

    @Test func aTemplateGivingTodaysNameIsAlreadyInPlace() {
        let plan = build([input("a.jpg"), input("b.jpg")], "{name}")

        #expect(plan.entries == [.alreadyInPlace(url("a.jpg")), .alreadyInPlace(url("b.jpg"))])
    }

    /// `A→B` while `B→C`: B vacates, so nothing is numbered.
    @Test func aShiftWithinTheRunNumbersNothing() {
        let a = MovePlanInput(url: url("A.jpg"), values: ["name": .text("B")])
        let b = MovePlanInput(url: url("B.jpg"), values: ["name": .text("C")])

        let plan = MovePlanBuilder.build(inputs: [a, b], companions: [:], template: NameTemplate("{name}"), listing: listing([], inputs: [a, b]))

        #expect(destinations(plan) == ["A.jpg": "B.jpg", "B.jpg": "C.jpg"])
    }

    @Test func aNameHeldOutsideTheRunNumbersTheGroupWithItsCompanions() throws {
        let raw = input("DSCF1.RAF")
        let companions = [raw.url: [url("DSCF1.xmp")]]

        let plan = build([raw], "Trip", companions: companions, others: ["Trip.xmp"])

        let group = try #require(plan.groups.first)
        #expect(group.destination.lastPathComponent == "Trip 1.RAF")
        #expect(group.companions.map(\.to.lastPathComponent) == ["Trip 1.xmp"])
    }

    @Test func twoFilesRenderingOneNameAreNumberedInOrder() {
        let plan = build([input("a.jpg"), input("b.jpg"), input("c.jpg")], "Trip")

        #expect(destinations(plan) == ["a.jpg": "Trip.jpg", "b.jpg": "Trip 1.jpg", "c.jpg": "Trip 2.jpg"])
    }

    /// The preview's "numbered" count: a group whose rendered name was taken, with its RAW partner.
    @Test func aPreviewNamesTheFilesItNumbered() {
        let inputs = [input("a.jpg"), input("DSCF1.RAF"), input("DSCF1.JPG"), input("Trip.jpg")]
        let builder = MovePlanBuilder(inputs: inputs, companions: [:], listing: listing([], inputs: inputs))

        let preview = builder.preview(template: NameTemplate("Trip"))

        #expect(preview.plan.entries.last == .alreadyInPlace(url("Trip.jpg")))
        #expect(preview.numbered == [url("a.jpg"), url("DSCF1.RAF"), url("DSCF1.JPG")])
        #expect(builder.preview(template: NameTemplate("{name}")).numbered.isEmpty)
    }

    @Test func anInPlaceFileKeepsItsNameHeld() {
        let plan = build([input("Trip.jpg"), input("b.jpg")], "Trip")

        #expect(plan.entries.first == .alreadyInPlace(url("Trip.jpg")))
        #expect(destinations(plan) == ["b.jpg": "Trip 1.jpg"])
    }

    // MARK: - Skips

    @Test func anOwnerWithBothEditRecordsKeepsBoth() {
        let photo = input("IMG_1234.HEIC")
        let companions = [photo.url: [url("IMG_1234.aae"), url("IMG_O1234.aae")]]

        let plan = build([photo], "Trip_{seq:3}", companions: companions)

        #expect(plan.groups.first?.companions.map(\.to.lastPathComponent) == ["Trip_001.aae", "Trip_001_O.aae"])
    }

    /// Two companions that one name would still merge skip their owner, and the rest is planned.
    @Test func companionsThatWouldMergeSkipTheirOwner() {
        let photo = input("IMG_1234.HEIC")
        let companions = [photo.url: [url("IMG_1234.aae"), url("IMG_1234.AAE")]]

        let plan = build([photo, input("IMG_2000.HEIC")], "Trip_{seq:3}", companions: companions)

        #expect(plan.entries.first == .skipped(photo.url, .companionNameClash))
        #expect(destinations(plan) == ["IMG_2000.HEIC": "Trip_001.HEIC"])
    }

    @Test func eachSkipThatNeedsNoDiskIsReported() {
        let plan = build([
            input("missing.jpg", isMissing: true),
            input("locked.jpg", isLocked: true),
            input("busy.jpg", isBusy: true),
        ], "Trip")

        #expect(plan.entries == [
            .skipped(url("missing.jpg"), .missing),
            .skipped(url("locked.jpg"), .locked),
            .skipped(url("busy.jpg"), .busy),
        ])
    }

    @Test func anEmptyRenderIsSkipped() {
        let plan = build([input("a.jpg")], "{title}")

        #expect(plan.entries == [.skipped(url("a.jpg"), .emptyName)])
    }

    @Test func numberingPastTheByteCapIsSkipped() {
        let long = String(repeating: "x", count: NameTemplate.maximumNameByteCount)
        let plan = build([input("a.jpg"), input("b.jpg")], long)

        #expect(plan.groups.first?.destination.lastPathComponent == "\(long).jpg")
        #expect(plan.entries.last == .skipped(url("b.jpg"), .overByteCap))
    }

    // MARK: - Case

    @Test func namesDifferingInCaseCollideOnlyOnACaseInsensitiveVolume() {
        let a = MovePlanInput(url: url("1.jpg"), values: ["name": .text("trip")])
        let b = MovePlanInput(url: url("2.JPG"), values: ["name": .text("Trip")])

        let insensitive = MovePlanBuilder.build(inputs: [a, b], companions: [:], template: NameTemplate("{name}"), listing: listing([], inputs: [a, b]))
        let sensitive = MovePlanBuilder.build(inputs: [a, b], companions: [:], template: NameTemplate("{name}"), listing: listing([], inputs: [a, b], caseSensitive: true))

        #expect(destinations(insensitive) == ["1.jpg": "trip.jpg", "2.JPG": "Trip 1.JPG"])
        #expect(destinations(sensitive) == ["1.jpg": "trip.jpg", "2.JPG": "Trip.JPG"])
    }

    // MARK: - Settling

    /// A group whose own skip is found while claiming no longer vacates its name, so the file that
    /// wanted it is numbered rather than refused.
    @Test func aGroupSkippedWhileClaimingIsHeldInPlaceForTheRest() {
        let photo = MovePlanInput(url: url("IMG_1234.HEIC"), values: ["name": .text("x")])
        let wantsIt = MovePlanInput(url: url("a.jpg"), values: ["name": .text("IMG_1234")])
        let companions = [photo.url: [url("IMG_1234.aae"), url("IMG_1234.AAE")]]

        let plan = MovePlanBuilder.build(
            inputs: [wantsIt, photo],
            companions: companions,
            template: NameTemplate("{name}"),
            listing: listing(["IMG_1234.aae", "IMG_1234.AAE"], inputs: [wantsIt, photo])
        )

        #expect(plan.entries.last == .skipped(photo.url, .companionNameClash))
        #expect(destinations(plan) == ["a.jpg": "IMG_1234.jpg"])
    }

    /// A file named only as another's companion moves with it and is no entry of its own.
    @Test func aCompanionThatIsAlsoAnInputIsNotAnEntry() {
        let still = input("IMG_1234.HEIC")
        let movie = input("IMG_1234.MOV")

        let plan = MovePlanBuilder.build(
            inputs: [still, movie],
            companions: [still.url: [movie.url]],
            template: NameTemplate("Trip"),
            listing: listing([], inputs: [still, movie])
        )

        #expect(plan.entries.count == 1)
        #expect(plan.groups.first?.companions.map(\.to.lastPathComponent) == ["Trip.MOV"])
    }

    // MARK: - One preparation, many templates

    /// A builder prepared once plans each template as a fresh build would, whatever came before.
    @Test func aPreparedBuilderPlansEachTemplateAsAFreshBuildWould() {
        let raw = input("DSCF1.RAF")
        let inputs = [raw, input("DSCF1.JPG"), input("b.jpg"), input("Trip.jpg"), input("c.jpg", isLocked: true)]
        let companions = [raw.url: [url("DSCF1.xmp")]]
        let listing = listing(["Trip 1.jpg", "DSCF1.xmp"], inputs: inputs)

        let builder = MovePlanBuilder(inputs: inputs, companions: companions, listing: listing)

        for template in ["Trip", "{name}", "Trip_{seq:3}", "{title}", "Trip"] {
            let fresh = MovePlanBuilder.build(inputs: inputs, companions: companions, template: NameTemplate(template), listing: listing)

            #expect(builder.plan(template: NameTemplate(template)) == fresh, "\(template)")
            #expect(builder.preview(template: NameTemplate(template)).plan == fresh, "\(template)")
        }
    }
}

/// The builder's last step asks the disk, which a listing can be out of step with.
@Suite(.tags(.file, .renameOrganize), .serialized)
final class MovePlanBuilderDiskTests: BinTestCase {
    /// The name is learned as taken and the file numbered, as a name the listing held would be.
    @Test func aNameTheListingMissedIsNumberedAround() throws {
        let a = bin.appendingPathComponent("a.jpg")
        let b = bin.appendingPathComponent("b.jpg")
        try Data().write(to: a)
        try Data().write(to: b)

        let stale = FolderListing.reading([bin])
        try Data().write(to: bin.appendingPathComponent("Trip_001.jpg"))

        let plan = MovePlanBuilder.build(
            inputs: [a, b].map { MovePlanInput(url: $0, values: NameTemplate.urlValues(for: $0)) },
            companions: [:],
            template: NameTemplate("Trip_{seq:3}"),
            listing: stale
        )

        #expect(plan.groups.map(\.destination.lastPathComponent) == ["Trip_001 1.jpg", "Trip_002.jpg"])
        #expect(FileCommands.moveConflicts(in: plan).isEmpty)
    }

    /// A keystroke's preview never asks the disk, so it trusts the listing.
    @Test func aPreviewTrustsTheListing() throws {
        let a = bin.appendingPathComponent("a.jpg")
        try Data().write(to: a)

        let stale = FolderListing.reading([bin])
        try Data().write(to: bin.appendingPathComponent("Trip.jpg"))

        let builder = MovePlanBuilder(inputs: [MovePlanInput(url: a, values: NameTemplate.urlValues(for: a))], companions: [:], listing: stale)

        #expect(builder.preview(template: NameTemplate("Trip")).plan.groups.map(\.destination.lastPathComponent) == ["Trip.jpg"])
        #expect(builder.plan(template: NameTemplate("Trip")).groups.map(\.destination.lastPathComponent) == ["Trip 1.jpg"])
    }

    @Test func aListingReadsEachFolderOnceAndItsCaseRule() throws {
        try Data().write(to: bin.appendingPathComponent("Trip.JPG"))

        let listing = FolderListing.reading([bin, bin])

        #expect(listing.contains(bin.appendingPathComponent("trip.jpg")) == !listing.isCaseSensitive(bin))
        #expect(listing.contains(bin.appendingPathComponent("Trip.JPG")))
    }
}
