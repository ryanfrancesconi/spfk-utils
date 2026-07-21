// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import SPFKBase
import Testing

@testable import SPFKUtils

@Suite
final class GroupByTagDirectoryTests {
    private let base = URL(filePath: "/output", directoryHint: .isDirectory)

    // MARK: - Empty / no-op cases

    @Test func emptyKeysReturnsBase() {
        let result = GroupByTagDirectory().resolve(base: base, tags: ["genre": "Jazz"])
        #expect(result == base)
    }

    @Test func keyAbsentFromTagsReturnsBase() {
        let result = GroupByTagDirectory(["genre"]).resolve(base: base, tags: ["mood": "Happy"])
        #expect(result == base)
    }

    @Test func keyWithEmptyValueReturnsBase() {
        let result = GroupByTagDirectory(["genre"]).resolve(base: base, tags: ["genre": ""])
        #expect(result == base)
    }

    @Test func keyWithWhitespaceOnlyValueReturnsBase() {
        let result = GroupByTagDirectory(["genre"]).resolve(base: base, tags: ["genre": "   "])
        #expect(result == base)
    }

    @Test func slashOnlyValueReturnsBase() {
        let result = GroupByTagDirectory(["genre"]).resolve(base: base, tags: ["genre": "///"])
        #expect(result == base)
    }

    // MARK: - Single key

    @Test func singleKeyFlatValue() {
        let result = GroupByTagDirectory(["genre"]).resolve(base: base, tags: ["genre": "Jazz"])
        #expect(result.path.hasSuffix("/output/Jazz"))
    }

    @Test func singleKeyNestedValue() {
        let result = GroupByTagDirectory(["genre"]).resolve(base: base, tags: ["genre": "Music/Classical"])
        #expect(result.path.hasSuffix("/output/Music/Classical"))
    }

    @Test func singleKeyTripleNested() {
        let result = GroupByTagDirectory(["grouping"]).resolve(base: base, tags: ["grouping": "A/B/C"])
        #expect(result.path.hasSuffix("/output/A/B/C"))
    }

    // MARK: - Multiple keys

    @Test func multipleKeysCreateNestedHierarchy() {
        let result = GroupByTagDirectory(["genre", "mood"]).resolve(
            base: base,
            tags: ["genre": "Jazz", "mood": "Happy"]
        )
        #expect(result.path.hasSuffix("/output/Jazz/Happy"))
    }

    @Test func multipleKeysMissingOneIsSkipped() {
        let result = GroupByTagDirectory(["genre", "mood", "category"]).resolve(
            base: base,
            tags: ["genre": "Jazz", "category": "Smooth"]
        )
        // "mood" absent — genre and category folders created, mood skipped
        #expect(result.path.hasSuffix("/output/Jazz/Smooth"))
    }

    @Test func multipleKeysAllMissingReturnsBase() {
        let result = GroupByTagDirectory(["genre", "mood"]).resolve(base: base, tags: ["bpm": "120"])
        #expect(result == base)
    }

    @Test func firstKeyNestedSecondKeyFlat() {
        let result = GroupByTagDirectory(["grouping", "mood"]).resolve(
            base: base,
            tags: ["grouping": "Music/Classical", "mood": "Calm"]
        )
        #expect(result.path.hasSuffix("/output/Music/Classical/Calm"))
    }

    // MARK: - Key ordering

    @Test func keyOrderDeterminesFolderOrder() {
        let resultAB = GroupByTagDirectory(["a", "b"]).resolve(
            base: base,
            tags: ["a": "Alpha", "b": "Beta"]
        )
        let resultBA = GroupByTagDirectory(["b", "a"]).resolve(
            base: base,
            tags: ["a": "Alpha", "b": "Beta"]
        )
        #expect(resultAB.path.hasSuffix("/Alpha/Beta"))
        #expect(resultBA.path.hasSuffix("/Beta/Alpha"))
    }

    // MARK: - Sanitization

    @Test func colonInValueReplacedWithDash() {
        let result = GroupByTagDirectory(["genre"]).resolve(base: base, tags: ["genre": "Rock:Hard"])
        #expect(!result.path.contains(":"))
        #expect(result.path.contains("-"))
    }

    @Test func leadingTrailingWhitespaceInValueIsTrimmed() {
        let result = GroupByTagDirectory(["genre"]).resolve(base: base, tags: ["genre": "  Jazz  "])
        #expect(result.path.hasSuffix("/Jazz"))
    }

    @Test func whitespaceAroundSlashSegmentsAreTrimmed() {
        let result = GroupByTagDirectory(["genre"]).resolve(base: base, tags: ["genre": " Music / Classical "])
        #expect(result.path.hasSuffix("/Music/Classical"))
    }

    @Test func emptySegmentsAfterSlashSplitAreDiscarded() {
        let result = GroupByTagDirectory(["genre"]).resolve(base: base, tags: ["genre": "A//B"])
        #expect(result.path.hasSuffix("/A/B"))
    }
}
