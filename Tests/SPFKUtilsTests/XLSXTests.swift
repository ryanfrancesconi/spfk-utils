// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
@testable import SPFKUtils
import Testing

struct XLSXTests {
    // MARK: - Writer → reader

    @Test func writtenWorkbookReadsBackToItsValues() throws {
        let header = ["Filename", "CatID", "Description", "Notes"]
        let rows = [
            ["001.wav", "00042", "Door, wood & <metal>", "Line one\r\nLine two"],
            ["002.wav", "", "Dröhnen 🎺", "\"quoted\" \u{1} control"],
            ["  padded  ", "007", "", "literal _x0041_ text"],
        ]

        let document = try XLSXReader.read(data: XLSXWriter.data(header: header, rows: rows, sheetName: "Sounds & FX"))

        #expect(document.sheets.count == 1)
        #expect(document.sheets[0].name == "Sounds & FX")
        #expect(document.sheets[0].rows == [header] + rows)
        #expect(document.encoding == nil)
        #expect(document.delimiter == nil)
    }

    #if os(macOS)
    @Test func aWrittenWorkbookPassesUnzipTest() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).xlsx")
        defer { try? FileManager.default.removeItem(at: url) }

        let rows = (0 ..< 500).map { ["\($0).wav", String(repeating: "keyword ", count: 10)] }
        try XLSXWriter.write(header: ["Filename", "Keywords"], rows: rows, to: url)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-t", url.path]
        process.standardOutput = Pipe()
        try process.run()
        process.waitUntilExit()

        #expect(process.terminationStatus == 0)
    }
    #endif

    @Test func tableDocumentPicksXLSXByContentNotExtension() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).txt")
        defer { try? FileManager.default.removeItem(at: url) }

        try XLSXWriter.write(header: ["Filename"], rows: [["a.wav"]], to: url)

        #expect(try TableDocument.read(contentsOf: url).sheets[0].rows == [["Filename"], ["a.wav"]])
    }

    // MARK: - Reading workbooks shaped like a vendor's

    /// Two data sheets, a non-data sheet, shared strings with rich-text and phonetic runs, a
    /// numeric year, a boolean, an Office `_x000D_` escape, a sparse row, a skipped row, and a
    /// sheet using a namespace prefix.
    private func vendorWorkbook() -> Data {
        let main = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
        let relationships = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"

        let workbook = """
        <workbook xmlns="\(main)" xmlns:r="\(relationships)"><sheets>\
        <sheet name="Pack One" sheetId="1" r:id="rId3"/>\
        <sheet name="Status" sheetId="2" r:id="rId1"/>\
        <sheet name="Pack Two" sheetId="3" r:id="rId2"/>\
        </sheets></workbook>
        """

        let workbookRelationships = """
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\
        <Relationship Id="rId1" Type="\(relationships)/worksheet" Target="worksheets/sheet2.xml"/>\
        <Relationship Id="rId2" Type="\(relationships)/worksheet" Target="/xl/worksheets/sheet3.xml"/>\
        <Relationship Id="rId3" Type="\(relationships)/worksheet" Target="worksheets/sheet1.xml"/>\
        <Relationship Id="rId4" Type="\(relationships)/sharedStrings" Target="sharedStrings.xml"/>\
        </Relationships>
        """

        let sharedStrings = """
        <sst xmlns="\(main)">\
        <si><t>Filename</t></si>\
        <si><t>TrackYear</t></si>\
        <si><t>Keywords</t></si>\
        <si><t>a.wav</t></si>\
        <si><r><t>door, </t></r><r><rPr><b/></rPr><t xml:space="preserve">wood</t></r><rPh><t>ignored</t></rPh></si>\
        <si><t>line_x000D_break</t></si>\
        <si><t>b.wav</t></si>\
        </sst>
        """

        let sheet1 = """
        <worksheet xmlns="\(main)"><sheetData>\
        <row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c><c r="C1" t="s"><v>2</v></c></row>\
        <row r="2"><c r="A2" t="s"><v>3</v></c><c r="B2"><v>2014</v></c><c r="C2" t="s"><v>4</v></c></row>\
        <row r="4"><c r="A4" t="s"><v>6</v></c><c r="C4" t="s"><v>5</v></c></row>\
        <row r="5"><c r="A5" t="inlineStr"><is><t>c.wav</t></is></c><c r="B5"><v>0.5</v></c><c r="D5" t="b"><v>1</v></c></row>\
        <row r="9" spans="1:3"/>\
        </sheetData></worksheet>
        """

        let sheet2 = """
        <worksheet xmlns="\(main)"><sheetData>\
        <row r="1"><c r="B1" t="inlineStr"><is><t>YES</t></is></c><c r="D1" t="inlineStr"><is><t>Designer</t></is></c></row>\
        </sheetData></worksheet>
        """

        let sheet3 = """
        <x:worksheet xmlns:x="\(main)"><x:sheetData>\
        <x:row><x:c t="inlineStr"><x:is><x:t>Filename</x:t></x:is></x:c></x:row>\
        <x:row><x:c t="str"><x:f>A1</x:f><x:v>d.wav</x:v></x:c></x:row>\
        </x:sheetData></x:worksheet>
        """

        return ZipArchive.archive([
            ("xl/workbook.xml", Data(workbook.utf8)),
            ("xl/_rels/workbook.xml.rels", Data(workbookRelationships.utf8)),
            ("xl/sharedStrings.xml", Data(sharedStrings.utf8)),
            ("xl/worksheets/sheet1.xml", Data(sheet1.utf8)),
            ("xl/worksheets/sheet2.xml", Data(sheet2.utf8)),
            ("xl/worksheets/sheet3.xml", Data(sheet3.utf8)),
        ])
    }

    @Test func sheetsReadInWorkbookOrderWithTheirNames() throws {
        let document = try XLSXReader.read(data: vendorWorkbook())

        #expect(document.sheets.map(\.name) == ["Pack One", "Status", "Pack Two"])
        #expect(document.sheets[1].rows == [["", "YES", "", "Designer"]])
        #expect(document.sheets[2].rows == [["Filename"], ["d.wav"]])
    }

    @Test func cellsResolveSharedStringsNumbersBooleansAndSparseReferences() throws {
        let sheet = try XLSXReader.read(data: vendorWorkbook()).sheets[0]

        #expect(sheet.rows == [
            ["Filename", "TrackYear", "Keywords"],
            ["a.wav", "2014", "door, wood"],
            ["", "", ""],
            ["b.wav", "", "line\rbreak"],
            ["c.wav", "0.5", "", "TRUE"],
        ])
        #expect(sheet.overlongRows == [4])
    }

    @Test(arguments: [("2014", "2014"), ("2014.0", "2014"), ("0.1", "0.1"), ("-3", "-3"), ("1E+20", "1e+20"), ("abc", "abc")])
    func numbersReadInTheirShortestForm(raw: String, expected: String) {
        #expect(XLSXReader.numberText(raw) == expected)
    }

    @Test func aMissingWorkbookPartThrows() {
        let data = ZipArchive.archive([("xl/_rels/workbook.xml.rels", Data("<Relationships/>".utf8))])

        #expect(throws: XLSXReaderError.missingPart("xl/workbook.xml")) {
            try XLSXReader.read(data: data)
        }
    }

    // MARK: - Escapes and references

    @Test(arguments: [
        ("a\rb", "a_x000D_b"),
        ("bell\u{7}", "bell_x0007_"),
        ("_x0041_", "_x005F_x0041_"),
        ("snake_case_x", "snake_case_x"),
        ("tab\tand\nnewline", "tab\tand\nnewline"),
    ])
    func escapesRoundTrip(text: String, encoded: String) {
        #expect(XLSXText.encodeEscapes(text) == encoded)
        #expect(XLSXText.decodeEscapes(encoded) == text)
    }

    @Test(arguments: [(0, "A"), (25, "Z"), (26, "AA"), (51, "AZ"), (52, "BA"), (701, "ZZ"), (702, "AAA")])
    func columnNamesAndReferencesAgree(index: Int, name: String) {
        #expect(XLSXText.columnName(index) == name)
        let reference = XLSXText.parseReference("\(name)12")
        #expect(reference.column == index)
        #expect(reference.row == 12)
    }
}
