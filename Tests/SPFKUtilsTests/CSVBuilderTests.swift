// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKUtils
import Testing

/// RFC 4180 escaping, which decides whether a written file parses back as the values that went
/// into it. Every branch here is reachable from ordinary audio metadata: BEXT coding history is
/// CRLF-delimited, notes and descriptions carry commas, comments carry quotes.
struct CSVBuilderTests {
    private func rows(_ csv: String) -> [String] {
        csv.components(separatedBy: "\r\n")
    }

    // MARK: - Escaping

    @Test func aFieldWithNoSpecialCharactersIsNotQuoted() {
        #expect(CSVBuilder.escapeField("Kick Drum") == "Kick Drum")
    }

    @Test func aFieldContainingACommaIsQuoted() {
        #expect(CSVBuilder.escapeField("Drums, Percussion") == "\"Drums, Percussion\"")
    }

    /// A quote is doubled *and* the field quoted -- doing only one of the two produces a field
    /// that a reader either terminates early or never terminates.
    @Test func aQuoteIsDoubledAndTheFieldQuoted() {
        #expect(CSVBuilder.escapeField("6\" cymbal") == "\"6\"\" cymbal\"")
    }

    @Test(arguments: ["Line one\nLine two", "Line one\r\nLine two", "Line one\rLine two"])
    func aFieldContainingANewlineIsQuoted(field: String) {
        #expect(CSVBuilder.escapeField(field) == "\"\(field)\"")
    }

    /// The newline survives the escape rather than being stripped or replaced: the quoting is what
    /// makes it legal, so rewriting the value would be a silent edit of the user's data.
    @Test func anEscapedNewlineIsPreserved() {
        let escaped = CSVBuilder.escapeField("A\r\nB")

        #expect(escaped.contains("\r\n"))
    }

    // MARK: - Assembly

    @Test func rowsAreSeparatedByCRLFAndHeadedByTheColumns() {
        let csv = CSVBuilder.build(columns: ["Name", "Take"], rows: ["a", "b"]) { [$0, "1"] }

        #expect(rows(csv) == ["Name,Take", "a,1", "b,1"])
    }

    /// The header goes through the same escaping as the values -- a column title carrying a comma
    /// would otherwise shift every field after it by one.
    @Test func columnTitlesAreEscapedLikeValues() {
        let csv = CSVBuilder.build(columns: ["Scene, Take"], rows: ["x"]) { [$0] }

        #expect(rows(csv).first == "\"Scene, Take\"")
    }

    @Test func noRowsWritesTheHeaderAlone() {
        let csv = CSVBuilder.build(columns: ["Name"], rows: [String]()) { [$0] }

        #expect(csv == "Name")
    }
}
