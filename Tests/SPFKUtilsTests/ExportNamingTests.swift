// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKBase
import SPFKFileSystem
import SPFKTesting
import Testing

@testable import SPFKUtils

@Suite(.tags(.conversion))
struct ExportNamingTests {
    private struct Item {
        var file: String
        var title: String?
    }

    private func names(_ naming: ExportNaming, _ items: [Item], collection: String = "Road Trip") -> [String] {
        naming.baseNames(for: items, fileName: \.file, title: \.title, collectionName: collection)
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
        #expect(result.allSatisfy { $0.utf8.count <= ExportNaming.maximumByteCount && $0.utf8.count > 200 })
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

    @Test func aStoredNamingRoundTrips() throws {
        let naming = ExportNaming(scheme: .sequential, prefix: "Take")
        #expect(try JSONDecoder().decode(ExportNaming.self, from: JSONEncoder().encode(naming)) == naming)
    }
}
