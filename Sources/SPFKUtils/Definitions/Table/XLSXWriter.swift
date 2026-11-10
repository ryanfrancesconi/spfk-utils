// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// Writes a one-sheet `.xlsx` workbook in which every cell is text, so a digit-only value such as
/// `001.wav` or a CatID keeps its leading zeros.
public enum XLSXWriter {
    public static func data(header: [String], rows: [[String]], sheetName: String = "Sheet1") -> Data {
        ZipArchive.archive([
            ("[Content_Types].xml", Data(contentTypes.utf8)),
            ("_rels/.rels", Data(packageRelationships.utf8)),
            (XLSXReader.workbookPath, Data(workbook(sheetName: sheetName).utf8)),
            (XLSXReader.workbookRelationshipsPath, Data(workbookRelationships.utf8)),
            ("xl/worksheets/sheet1.xml", worksheet(rows: [header] + rows)),
        ])
    }

    public static func write(header: [String], rows: [[String]], sheetName: String = "Sheet1", to url: URL) throws {
        try data(header: header, rows: rows, sheetName: sheetName).write(to: url, options: .atomic)
    }

    // MARK: - Parts

    private static let declaration = #"<?xml version="1.0" encoding="UTF-8" standalone="yes"?>"#
    private static let spreadsheetNamespace = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
    private static let relationshipNamespace = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
    private static let packageRelationshipNamespace = "http://schemas.openxmlformats.org/package/2006/relationships"

    private static let contentTypes = declaration + """
    <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\
    <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\
    <Default Extension="xml" ContentType="application/xml"/>\
    <Override PartName="/xl/workbook.xml" \
    ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>\
    <Override PartName="/xl/worksheets/sheet1.xml" \
    ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>\
    </Types>
    """

    private static let packageRelationships = declaration + """
    <Relationships xmlns="\(packageRelationshipNamespace)">\
    <Relationship Id="rId1" Type="\(relationshipNamespace)/officeDocument" Target="xl/workbook.xml"/>\
    </Relationships>
    """

    private static let workbookRelationships = declaration + """
    <Relationships xmlns="\(packageRelationshipNamespace)">\
    <Relationship Id="rId1" Type="\(relationshipNamespace)/worksheet" Target="worksheets/sheet1.xml"/>\
    </Relationships>
    """

    private static func workbook(sheetName: String) -> String {
        declaration + """
        <workbook xmlns="\(spreadsheetNamespace)" xmlns:r="\(relationshipNamespace)">\
        <sheets><sheet name="\(XLSXText.escapeXML(sheetName))" sheetId="1" r:id="rId1"/></sheets>\
        </workbook>
        """
    }

    private static func worksheet(rows: [[String]]) -> Data {
        var xml = declaration + #"<worksheet xmlns="\#(spreadsheetNamespace)"><sheetData>"#
        let columnNames = (0 ..< (rows.map(\.count).max() ?? 0)).map(XLSXText.columnName)

        for (rowIndex, row) in rows.enumerated() {
            let rowNumber = String(rowIndex + 1)
            xml += #"<row r="\#(rowNumber)">"#

            // A cell needs its reference only when an empty cell before it was left out.
            var previousWritten = -1

            for (columnIndex, value) in row.enumerated() where !value.isEmpty {
                if columnIndex == previousWritten + 1 {
                    xml += #"<c t="inlineStr">"#
                } else {
                    xml += #"<c r="\#(columnNames[columnIndex])\#(rowNumber)" t="inlineStr">"#
                }

                let edgeWhitespace = value.first?.isWhitespace == true || value.last?.isWhitespace == true
                xml += edgeWhitespace ? #"<is><t xml:space="preserve">"# : "<is><t>"
                xml += XLSXText.escapeXML(XLSXText.encodeEscapes(value))
                xml += "</t></is></c>"
                previousWritten = columnIndex
            }

            xml += "</row>"
        }

        xml += "</sheetData></worksheet>"
        return Data(xml.utf8)
    }
}
