// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKBase
import SPFKFileSystem
import SPFKTesting
import Testing

@testable import SPFKUtils

@Suite(.tags(.conversion, .nameTemplate))
struct ExportNamingTests {
    private struct Item {
        var file: String
        var title: String?
    }

    private func names(_ naming: ExportNaming, _ items: [Item], collection: String = "Road Trip") -> [String] {
        naming.baseNames(for: items, values: { item in
            var values: [String: NameTemplate.Value] = ["name": .text(item.file)]
            values["title"] = item.title.map { .text($0) }
            return values
        }, collectionName: collection)
    }

    private let items = [Item(file: "kick", title: "Kick Drum"), Item(file: "snare", title: "Snare")]

    @Test func useFileNameKeepsEachFilesName() {
        #expect(names(ExportNaming(scheme: .fileName), items) == ["kick", "snare"])
    }

    @Test func useTitleNamesEachFileByItsTitle() {
        #expect(names(ExportNaming(scheme: .title), items) == ["Kick Drum", "Snare"])
    }

    @Test(arguments: [nil, "", "   "])
    func anEmptyTitleFallsBackToTheFileName(title: String?) {
        #expect(names(ExportNaming(scheme: .title), [Item(file: "kick", title: title)]) == ["kick"])
    }

    @Test func sequentialNumbersInTheOrderGiven() {
        #expect(names(ExportNaming(scheme: .sequential, prefix: "Take"), items) == ["Take 1", "Take 2"])
        #expect(names(ExportNaming(scheme: .sequential, prefix: "Take"), items.reversed()) == ["Take 1", "Take 2"])
        #expect(names(ExportNaming(scheme: .sequential), items) == ["1", "2"])
    }

    @Test func theCollectionNameLeadsTheNumber() {
        #expect(names(ExportNaming(scheme: .collectionNameWithNumber), items) == ["Road Trip 1", "Road Trip 2"])
    }

    /// Padded to the count's width, so Finder lists 10 after 9.
    @Test func numbersArePaddedToTheCountsWidth() {
        let many = (1 ... 12).map { Item(file: "f\($0)") }
        let result = names(ExportNaming(scheme: .sequential, prefix: "Take"), many)

        #expect(result.first == "Take 01")
        #expect(result.last == "Take 12")
        #expect(result == result.sorted())
    }

    @Test func aNameIsMadeSafeForTheFileSystem() {
        let unsafe = [Item(file: "x", title: "  ..AC/DC: Live  ")]
        #expect(names(ExportNaming(scheme: .title), unsafe) == ["AC-DC- Live"])
    }

    @Test func aLongTitleIsShortenedOnWholeCharacters() {
        let long = String(repeating: "é", count: 200)
        let result = names(ExportNaming(scheme: .title), [Item(file: "x", title: long)])

        #expect(result.count == 1)
        #expect(result.allSatisfy { $0.utf8.count <= NameTemplate.maximumNameByteCount && $0.utf8.count > 200 })
        #expect(result.allSatisfy { $0.allSatisfy { $0 == "é" } })
    }

    /// Two files sharing a title are told apart by the batch's claiming, not by the naming.
    @Test func aSharedTitleIsNumberedApartByTheClaims() throws {
        let bin = FileManager.default.temporaryDirectory.appending(component: "ExportNamingTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: bin) }

        let base = names(ExportNaming(scheme: .title), [Item(file: "a", title: "Same"), Item(file: "b", title: "Same")])
        let claims = base.map {
            BatchOutputClaims.Claim(output: bin.appending(component: "\($0).wav"), conflictScheme: .overwrite, inputs: [])
        }

        let outputs = try BatchOutputClaims.resolve(claims).map { try $0.get().output.lastPathComponent }

        #expect(outputs.first == "Same.wav")
        #expect(Set(outputs).count == 2)
    }

    @Test func aNamingSavedBeforeTemplatesDecodes() throws {
        let saved = Data(#"{"scheme":"sequential","prefix":"Trip"}"#.utf8)
        let naming = try JSONDecoder().decode(ExportNaming.self, from: saved)

        #expect(naming == ExportNaming(scheme: .sequential, prefix: "Trip"))
        #expect(naming.template.isEmpty)
    }

    @Test func aCustomNamingRoundTrips() throws {
        let naming = ExportNaming(scheme: .custom, template: "{date:YYYY-MM-DD}_{seq:2}")
        #expect(try JSONDecoder().decode(ExportNaming.self, from: JSONEncoder().encode(naming)) == naming)
    }

    @Test func customRendersItsTemplate() {
        let naming = ExportNaming(scheme: .custom, template: "{date:YYYY-MM-DD}_{seq:2}_{field:camera}")
        let dates = [NameTemplate.DateParts(year: 2019, month: 5, day: 7), nil, .init(year: 2020, month: 1, day: 2)]

        let result = naming.baseNames(for: Array(dates.enumerated()), values: { offset, date in
            var values: [String: NameTemplate.Value] = ["name": .text("IMG_\(offset)"), "field:camera": .text("X100V")]
            values["date"] = date.map { .date($0) }
            return values
        }, collectionName: "")

        #expect(result == ["2019-05-07_01_X100V", "_02_X100V", "2020-01-02_03_X100V"])
    }

    @Test func anEmptyCustomNameFallsBackToTheFileName() {
        #expect(names(ExportNaming(scheme: .custom, template: "{title}"), [Item(file: ".kick")]) == ["kick"])
    }

    @Test func aStoredNamingRoundTrips() throws {
        let naming = ExportNaming(scheme: .sequential, prefix: "Take")
        #expect(try JSONDecoder().decode(ExportNaming.self, from: JSONEncoder().encode(naming)) == naming)
    }

    // MARK: - Before templates

    private static let inputs = [
        "", "   ", " Foo ", ".hidden", "a/b:c", String(repeating: "é", count: 150), "abc  ", ".x", String(repeating: "p", count: 245),
    ]

    /// Each scheme's first and last name, as `baseNames` gave them before naming went through
    /// templates. Each input serves as the file name stem, the title, the prefix and the collection.
    /// One row changed: an over-long prefix is cut with the whole name, so its number is cut too.
    private static var namesBeforeTemplates: [(ExportNaming.Scheme, Int, Int, String, String)] {
        let e = String(repeating: "é", count: 120)
        let p = String(repeating: "p", count: 240)

        return [
            (.fileName, 1, 0, "1", "1"),
            (.fileName, 1, 1, "1", "1"),
            (.fileName, 1, 2, "Foo 1", "Foo 1"),
            (.fileName, 1, 3, "hidden1", "hidden1"),
            (.fileName, 1, 4, "a-b-c1", "a-b-c1"),
            (.fileName, 1, 5, "\(e)", "\(e)"),
            (.fileName, 1, 6, "abc  1", "abc  1"),
            (.fileName, 1, 7, "x1", "x1"),
            (.fileName, 1, 8, "\(p)", "\(p)"),
            (.fileName, 9, 0, "1", "9"),
            (.fileName, 9, 1, "1", "9"),
            (.fileName, 9, 2, "Foo 1", "Foo 9"),
            (.fileName, 9, 3, "hidden1", "hidden9"),
            (.fileName, 9, 4, "a-b-c1", "a-b-c9"),
            (.fileName, 9, 5, "\(e)", "\(e)"),
            (.fileName, 9, 6, "abc  1", "abc  9"),
            (.fileName, 9, 7, "x1", "x9"),
            (.fileName, 9, 8, "\(p)", "\(p)"),
            (.fileName, 10, 0, "1", "10"),
            (.fileName, 10, 1, "1", "10"),
            (.fileName, 10, 2, "Foo 1", "Foo 10"),
            (.fileName, 10, 3, "hidden1", "hidden10"),
            (.fileName, 10, 4, "a-b-c1", "a-b-c10"),
            (.fileName, 10, 5, "\(e)", "\(e)"),
            (.fileName, 10, 6, "abc  1", "abc  10"),
            (.fileName, 10, 7, "x1", "x10"),
            (.fileName, 10, 8, "\(p)", "\(p)"),
            (.fileName, 100, 0, "1", "100"),
            (.fileName, 100, 1, "1", "100"),
            (.fileName, 100, 2, "Foo 1", "Foo 100"),
            (.fileName, 100, 3, "hidden1", "hidden100"),
            (.fileName, 100, 4, "a-b-c1", "a-b-c100"),
            (.fileName, 100, 5, "\(e)", "\(e)"),
            (.fileName, 100, 6, "abc  1", "abc  100"),
            (.fileName, 100, 7, "x1", "x100"),
            (.fileName, 100, 8, "\(p)", "\(p)"),
            (.title, 1, 0, "1", "1"),
            (.title, 1, 1, "1", "1"),
            (.title, 1, 2, "Foo", "Foo"),
            (.title, 1, 3, "hidden", "hidden"),
            (.title, 1, 4, "a-b-c", "a-b-c"),
            (.title, 1, 5, "\(e)", "\(e)"),
            (.title, 1, 6, "abc", "abc"),
            (.title, 1, 7, "x", "x"),
            (.title, 1, 8, "\(p)", "\(p)"),
            (.title, 9, 0, "1", "9"),
            (.title, 9, 1, "1", "9"),
            (.title, 9, 2, "Foo", "Foo"),
            (.title, 9, 3, "hidden", "hidden"),
            (.title, 9, 4, "a-b-c", "a-b-c"),
            (.title, 9, 5, "\(e)", "\(e)"),
            (.title, 9, 6, "abc", "abc"),
            (.title, 9, 7, "x", "x"),
            (.title, 9, 8, "\(p)", "\(p)"),
            (.title, 10, 0, "1", "10"),
            (.title, 10, 1, "1", "10"),
            (.title, 10, 2, "Foo", "Foo"),
            (.title, 10, 3, "hidden", "hidden"),
            (.title, 10, 4, "a-b-c", "a-b-c"),
            (.title, 10, 5, "\(e)", "\(e)"),
            (.title, 10, 6, "abc", "abc"),
            (.title, 10, 7, "x", "x"),
            (.title, 10, 8, "\(p)", "\(p)"),
            (.title, 100, 0, "1", "100"),
            (.title, 100, 1, "1", "100"),
            (.title, 100, 2, "Foo", "Foo"),
            (.title, 100, 3, "hidden", "hidden"),
            (.title, 100, 4, "a-b-c", "a-b-c"),
            (.title, 100, 5, "\(e)", "\(e)"),
            (.title, 100, 6, "abc", "abc"),
            (.title, 100, 7, "x", "x"),
            (.title, 100, 8, "\(p)", "\(p)"),
            (.sequential, 1, 0, "1", "1"),
            (.sequential, 1, 1, "1", "1"),
            (.sequential, 1, 2, "Foo 1", "Foo 1"),
            (.sequential, 1, 3, "hidden 1", "hidden 1"),
            (.sequential, 1, 4, "a-b-c 1", "a-b-c 1"),
            (.sequential, 1, 5, "\(e)", "\(e)"),
            (.sequential, 1, 6, "abc 1", "abc 1"),
            (.sequential, 1, 7, "x 1", "x 1"),
            (.sequential, 1, 8, "\(p)", "\(p)"),
            (.sequential, 9, 0, "1", "9"),
            (.sequential, 9, 1, "1", "9"),
            (.sequential, 9, 2, "Foo 1", "Foo 9"),
            (.sequential, 9, 3, "hidden 1", "hidden 9"),
            (.sequential, 9, 4, "a-b-c 1", "a-b-c 9"),
            (.sequential, 9, 5, "\(e)", "\(e)"),
            (.sequential, 9, 6, "abc 1", "abc 9"),
            (.sequential, 9, 7, "x 1", "x 9"),
            (.sequential, 9, 8, "\(p)", "\(p)"),
            (.sequential, 10, 0, "01", "10"),
            (.sequential, 10, 1, "01", "10"),
            (.sequential, 10, 2, "Foo 01", "Foo 10"),
            (.sequential, 10, 3, "hidden 01", "hidden 10"),
            (.sequential, 10, 4, "a-b-c 01", "a-b-c 10"),
            (.sequential, 10, 5, "\(e)", "\(e)"),
            (.sequential, 10, 6, "abc 01", "abc 10"),
            (.sequential, 10, 7, "x 01", "x 10"),
            (.sequential, 10, 8, "\(p)", "\(p)"),
            (.sequential, 100, 0, "001", "100"),
            (.sequential, 100, 1, "001", "100"),
            (.sequential, 100, 2, "Foo 001", "Foo 100"),
            (.sequential, 100, 3, "hidden 001", "hidden 100"),
            (.sequential, 100, 4, "a-b-c 001", "a-b-c 100"),
            (.sequential, 100, 5, "\(e)", "\(e)"),
            (.sequential, 100, 6, "abc 001", "abc 100"),
            (.sequential, 100, 7, "x 001", "x 100"),
            (.sequential, 100, 8, "\(p)", "\(p)"),
            (.collectionNameWithNumber, 1, 0, "1", "1"),
            (.collectionNameWithNumber, 1, 1, "1", "1"),
            (.collectionNameWithNumber, 1, 2, "Foo 1", "Foo 1"),
            (.collectionNameWithNumber, 1, 3, "hidden 1", "hidden 1"),
            (.collectionNameWithNumber, 1, 4, "a-b-c 1", "a-b-c 1"),
            (.collectionNameWithNumber, 1, 5, "\(e)", "\(e)"),
            (.collectionNameWithNumber, 1, 6, "abc 1", "abc 1"),
            (.collectionNameWithNumber, 1, 7, "x 1", "x 1"),
            (.collectionNameWithNumber, 1, 8, "\(p)", "\(p)"),
            (.collectionNameWithNumber, 9, 0, "1", "9"),
            (.collectionNameWithNumber, 9, 1, "1", "9"),
            (.collectionNameWithNumber, 9, 2, "Foo 1", "Foo 9"),
            (.collectionNameWithNumber, 9, 3, "hidden 1", "hidden 9"),
            (.collectionNameWithNumber, 9, 4, "a-b-c 1", "a-b-c 9"),
            (.collectionNameWithNumber, 9, 5, "\(e)", "\(e)"),
            (.collectionNameWithNumber, 9, 6, "abc 1", "abc 9"),
            (.collectionNameWithNumber, 9, 7, "x 1", "x 9"),
            (.collectionNameWithNumber, 9, 8, "\(p)", "\(p)"),
            (.collectionNameWithNumber, 10, 0, "01", "10"),
            (.collectionNameWithNumber, 10, 1, "01", "10"),
            (.collectionNameWithNumber, 10, 2, "Foo 01", "Foo 10"),
            (.collectionNameWithNumber, 10, 3, "hidden 01", "hidden 10"),
            (.collectionNameWithNumber, 10, 4, "a-b-c 01", "a-b-c 10"),
            (.collectionNameWithNumber, 10, 5, "\(e)", "\(e)"),
            (.collectionNameWithNumber, 10, 6, "abc 01", "abc 10"),
            (.collectionNameWithNumber, 10, 7, "x 01", "x 10"),
            (.collectionNameWithNumber, 10, 8, "\(p)", "\(p)"),
            (.collectionNameWithNumber, 100, 0, "001", "100"),
            (.collectionNameWithNumber, 100, 1, "001", "100"),
            (.collectionNameWithNumber, 100, 2, "Foo 001", "Foo 100"),
            (.collectionNameWithNumber, 100, 3, "hidden 001", "hidden 100"),
            (.collectionNameWithNumber, 100, 4, "a-b-c 001", "a-b-c 100"),
            (.collectionNameWithNumber, 100, 5, "\(e)", "\(e)"),
            (.collectionNameWithNumber, 100, 6, "abc 001", "abc 100"),
            (.collectionNameWithNumber, 100, 7, "x 001", "x 100"),
            (.collectionNameWithNumber, 100, 8, "\(p)", "\(p)"),
        ]
    }

    @Test func everySchemeNamesAsItDidBeforeTemplates() {
        for (scheme, count, input, first, last) in Self.namesBeforeTemplates {
            let text = Self.inputs[input]
            let items = (1 ... count).map { Item(file: "\(text)\($0)", title: text) }
            let result = names(ExportNaming(scheme: scheme, prefix: text), items, collection: text)

            #expect(result.first == first, "\(scheme) \(count) input \(input)")
            #expect(result.last == last, "\(scheme) \(count) input \(input)")
        }
    }
}
