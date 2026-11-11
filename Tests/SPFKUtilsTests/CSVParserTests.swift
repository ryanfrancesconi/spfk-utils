// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKTesting
import SPFKUtils
import Testing

@Suite(.tags(.spreadsheetImport))
struct CSVParserTests {
    private func rows(_ text: String, delimiter: Character? = nil) throws -> [[String]] {
        try CSVParser.parse(Data(text.utf8), delimiter: delimiter).sheets[0].rows
    }

    // MARK: - Round trip

    @Test func builderOutputParsesBackToItsValues() throws {
        let values = [
            ["Name", "Notes", "Take"],
            ["Door, wood", "6\" cymbal", "1"],
            ["Line one\r\nLine two", "Line\nthree", "Line\rfour"],
            ["Dröhnen 🎺", "\"quoted\"", ""],
            ["  padded  ", ",", "\"\""],
        ]

        for delimiter: Character in [",", "\t", ";"] {
            let text = CSVBuilder.build(columns: values[0], rows: Array(values.dropFirst()), delimiter: delimiter) { $0 }
            let document = try CSVParser.parse(Data(text.utf8))

            #expect(document.sheets[0].rows == values)
            #expect(document.delimiter == delimiter)
        }
    }

    // MARK: - Records

    @Test(arguments: ["a,b\r\nc,d", "a,b\nc,d", "a,b\rc,d", "a,b\r\nc,d\r\n", "a,b\nc,d\n"])
    func lineEndingsAndATrailingNewlineGiveTwoRows(text: String) throws {
        #expect(try rows(text) == [["a", "b"], ["c", "d"]])
    }

    @Test func shortRowsArePaddedAndLongRowsKeptAndReported() throws {
        let sheet = try CSVParser.parse(Data("a,b,c\n1\n1,2,3,4\n".utf8)).sheets[0]

        #expect(sheet.rows == [["a", "b", "c"], ["1", "", ""], ["1", "2", "3", "4"]])
        #expect(sheet.overlongRows == [2])
    }

    @Test func trailingEmptyRowsAreDroppedButInteriorOnesKept() throws {
        #expect(try rows("a,b\n,\n1,2\n,\n,\n") == [["a", "b"], ["", ""], ["1", "2"]])
    }

    @Test func aWhitespaceOnlyCellIsKeptVerbatim() throws {
        #expect(try rows("a,b\n   ,\t\n", delimiter: ",") == [["a", "b"], ["   ", "\t"]])
    }

    @Test func aQuoteInsideAnUnquotedFieldIsLiteral() throws {
        #expect(try rows("a,b\n6\" cymbal,x") == [["a", "b"], ["6\" cymbal", "x"]])
    }

    @Test func textAfterAClosingQuoteIsAppended() throws {
        #expect(try rows("a,b\n\"one\" two,x") == [["a", "b"], ["one two", "x"]])
    }

    @Test func anUnterminatedQuoteThrowsNamingItsRow() {
        #expect(throws: CSVParserError.unterminatedQuote(row: 3)) {
            try CSVParser.parse(Data("a,b\n1,2\n\"open,3\n4,5\n".utf8))
        }
    }

    @Test func emptyInputHasNoRows() throws {
        #expect(try rows("") == [])
    }

    // MARK: - Delimiter

    @Test func aSemicolonFileKeepsDecimalCommasInQuotedCells() throws {
        let document = try CSVParser.parse(Data("Name;BPM;Gain\nkick;\"120,5\";\"-3,0\"\n".utf8))

        #expect(document.delimiter == ";")
        #expect(document.sheets[0].rows[1] == ["kick", "120,5", "-3,0"])
    }

    /// The sniff counts only the header, and only outside quotes.
    @Test func delimitersInsideQuotedHeadersDoNotCount() {
        #expect(CSVParser.sniffDelimiter("\"a,b,c\"\t\"d,e\"\tf\n1,2,3,4,5,6") == "\t")
    }

    @Test(arguments: [("a\tb,c", "\t"), ("a,b;c", ","), ("a;b;c,d", ";"), ("single", ",")] as [(String, Character)])
    func tiesGoToTabThenComma(header: String, expected: Character) {
        #expect(CSVParser.sniffDelimiter(header) == expected)
    }

    @Test func aGivenDelimiterOverridesTheSniff() throws {
        #expect(try rows("a,b;c", delimiter: ";") == [["a,b", "c"]])
    }

    @Test func aNewlineDelimiterIsRefused() {
        #expect(throws: CSVParserError.unsupportedDelimiter("\n")) {
            try CSVParser.parse(Data("a".utf8), delimiter: "\n")
        }
    }

    // MARK: - Encoding

    @Test func aUTF8ByteOrderMarkIsDetectedAndStripped() throws {
        let document = try CSVParser.parse(Data([0xEF, 0xBB, 0xBF] + Array("Filename,é\n".utf8)))

        #expect(document.encoding == .utf8)
        #expect(document.sheets[0].rows == [["Filename", "é"]])
    }

    @Test(arguments: [String.Encoding.utf16LittleEndian, .utf16BigEndian])
    func utf16TabTextWithAByteOrderMarkIsDetected(encoding: String.Encoding) throws {
        let bom: [UInt8] = encoding == .utf16LittleEndian ? [0xFF, 0xFE] : [0xFE, 0xFF]
        let body = try #require("Filename\tDescription\r\ndoor.wav\tDröhnen 🎺\r\n".data(using: encoding))
        let document = try CSVParser.parse(Data(bom) + body)

        #expect(document.encoding == encoding)
        #expect(document.delimiter == "\t")
        #expect(document.sheets[0].rows == [["Filename", "Description"], ["door.wav", "Dröhnen 🎺"]])
    }

    @Test func plainUTF8IsDetectedWithoutAByteOrderMark() throws {
        #expect(try CSVParser.parse(Data("a,é".utf8)).encoding == .utf8)
    }

    /// 0xE9 alone is not valid UTF-8, so the file falls back to the Windows code page.
    @Test func aWindows1252ByteFallsBackFromUTF8() throws {
        let document = try CSVParser.parse(Data(Array("Name\ncaf".utf8) + [0xE9, 0x80]))

        #expect(document.encoding == .windowsCP1252)
        #expect(document.sheets[0].rows[1] == ["café€"])
    }

    /// 0x81 is undefined in Windows-1252, which then refuses the whole file.
    @Test func aByteUndefinedInWindows1252FallsBackToLatin1() throws {
        let document = try CSVParser.parse(Data(Array("Name\nx".utf8) + [0x81, 0xE9]))

        #expect(document.encoding == .isoLatin1)
        #expect(document.sheets[0].rows[1] == ["x\u{81}é"])
    }

    @Test func aGivenEncodingIsUsedAndAMismatchThrows() throws {
        let macRoman = Data(Array("Name\ncaf".utf8) + [0x8E])

        #expect(try CSVParser.parse(macRoman, encoding: .macOSRoman).sheets[0].rows[1] == ["café"])
        #expect(throws: CSVParserError.undecodable(.utf8)) {
            try CSVParser.parse(macRoman, encoding: .utf8)
        }
    }

    @Test func aGivenEncodingStillDropsAByteOrderMark() throws {
        let document = try CSVParser.parse(Data([0xEF, 0xBB, 0xBF] + Array("a,b".utf8)), encoding: .utf8)

        #expect(document.sheets[0].rows == [["a", "b"]])
    }
}
