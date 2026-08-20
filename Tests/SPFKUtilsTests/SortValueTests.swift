// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import Testing

@testable import SPFKUtils

/// The ordering rule for table columns of mixed type. Cross-type comparison is the part no caller
/// can infer: a column can hold numbers in some rows and text in others.
@Suite
struct SortValueTests {
    // MARK: - Same type

    @Test func stringsCompareByLocalizedStandardOrder() {
        #expect(SortValue.string("a") < SortValue.string("b"))
        #expect(!(SortValue.string("b") < SortValue.string("a")))
    }

    /// Localized standard order is why "file 2" precedes "file 10" — a plain lexicographic compare
    /// puts them the other way, and a table of numbered takes reads as scrambled.
    @Test func stringsOrderNumericRunsByValue() {
        #expect(SortValue.string("take 2.wav") < SortValue.string("take 10.wav"))
    }

    @Test func doublesCompareNumerically() {
        #expect(SortValue.double(1.5) < SortValue.double(2.0))
        #expect(!(SortValue.double(2.0) < SortValue.double(1.5)))
    }

    @Test func integersCompareNumerically() {
        #expect(SortValue.integer(1) < SortValue.integer(2))
    }

    // MARK: - Mixed numeric

    @Test func integersAndDoublesCompareAcrossTheirTypes() {
        #expect(SortValue.integer(1) < SortValue.double(1.5))
        #expect(SortValue.double(1.5) < SortValue.integer(2))
        #expect(!(SortValue.double(2.0) < SortValue.integer(2)))
        #expect(!(SortValue.integer(2) < SortValue.double(2.0)))
    }

    // MARK: - Numeric vs string

    @Test func numericsSortBeforeStrings() {
        #expect(SortValue.integer(9) < SortValue.string("a"))
        #expect(SortValue.double(9.0) < SortValue.string("a"))
        #expect(!(SortValue.string("a") < SortValue.integer(9)))
        #expect(!(SortValue.string("a") < SortValue.double(9.0)))
    }

    /// The rule holds regardless of the numeral's text — it is a type rule, not a value rule.
    @Test func numericsSortBeforeStringsThatLookNumeric() {
        #expect(SortValue.integer(100) < SortValue.string("1"))
    }

    // MARK: - Equality is not orderedness

    /// `<` must be false in both directions for equal values, which is what lets a caller detect a
    /// tie. Every equal pair, across all three cases.
    @Test(arguments: [SortValue.string("x"), .double(1.5), .integer(3)])
    func equalValuesAreNotOrderedEitherWay(value: SortValue) {
        #expect(!(value < value))
    }

    /// Numerically equal but differently padded is an *order*, not a tie — the unpadded form comes
    /// first. Pinned because it is the case that looks like it should tie and does not, which is
    /// what a caller distinguishing equal from ordered depends on.
    @Test func differentlyPaddedNumeralsAreOrderedRatherThanTied() {
        #expect(SortValue.string("File 1") < SortValue.string("File 01"))
        #expect(!(SortValue.string("File 01") < SortValue.string("File 1")))
    }

    /// Case differs only in order, and lowercase leads.
    @Test func caseDiffersInOrderRatherThanTying() {
        #expect(SortValue.string("a") < SortValue.string("A"))
        #expect(!(SortValue.string("A") < SortValue.string("a")))
    }
}
