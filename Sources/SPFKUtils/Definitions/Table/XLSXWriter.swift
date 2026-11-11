// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// Writes a one-sheet `.xlsx` workbook in which every cell is text, so a digit-only value such as
/// `001.wav` or a CatID keeps its leading zeros. The header row is bold and frozen, and each column
/// is sized to its longest value.
public enum XLSXWriter {
    public static func data(header: [String], rows: [[String]], sheetName: String = "Sheet1") -> Data {
        ZipArchive.archive([
            ("[Content_Types].xml", Data(contentTypes.utf8)),
            ("_rels/.rels", Data(packageRelationships.utf8)),
            (XLSXReader.workbookPath, Data(workbook(sheetName: sheetName).utf8)),
            (XLSXReader.workbookRelationshipsPath, Data(workbookRelationships.utf8)),
            ("xl/styles.xml", Data(styles.utf8)),
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
    <Override PartName="/xl/styles.xml" \
    ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>\
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
    <Relationship Id="rId2" Type="\(relationshipNamespace)/styles" Target="styles.xml"/>\
    </Relationships>
    """

    /// Style 0 is plain text, style 1 the bold header. Without a style part, Numbers wraps every cell.
    private static let styles = declaration + """
    <styleSheet xmlns="\(spreadsheetNamespace)">\
    <fonts count="2"><font><sz val="12"/><name val="Calibri"/><family val="2"/></font>\
    <font><b/><sz val="12"/><name val="Calibri"/><family val="2"/></font></fonts>\
    <fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>\
    <borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>\
    <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>\
    <cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>\
    <xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/></cellXfs>\
    <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>\
    </styleSheet>
    """

    /// Column widths in characters, from the longest value in each column.
    static func columnWidths(_ rows: [[String]]) -> [Int] {
        var widths = [Int](repeating: 0, count: rows.map(\.count).max() ?? 0)

        for row in rows {
            for (index, value) in row.enumerated() where value.count > widths[index] {
                widths[index] = value.count
            }
        }

        return widths.map { min(max($0 + 2, minimumWidth), maximumWidth) }
    }

    static let minimumWidth = 8
    static let maximumWidth = 60

    private static func workbook(sheetName: String) -> String {
        declaration + """
        <workbook xmlns="\(spreadsheetNamespace)" xmlns:r="\(relationshipNamespace)">\
        <sheets><sheet name="\(XLSXText.escapeXML(sheetName))" sheetId="1" r:id="rId1"/></sheets>\
        </workbook>
        """
    }

    private static func worksheet(rows: [[String]]) -> Data {
        var xml = declaration + #"<worksheet xmlns="\#(spreadsheetNamespace)">"#
        xml += #"<sheetViews><sheetView workbookViewId="0">"#
        xml += #"<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>"#
        xml += #"</sheetView></sheetViews><sheetFormatPr defaultRowHeight="16"/>"#

        let widths = columnWidths(rows)
        if !widths.isEmpty {
            xml += "<cols>"
            for (index, width) in widths.enumerated() {
                xml += #"<col min="\#(index + 1)" max="\#(index + 1)" width="\#(width)" customWidth="1"/>"#
            }
            xml += "</cols>"
        }

        xml += "<sheetData>"
        let columnNames = (0 ..< widths.count).map(XLSXText.columnName)

        for (rowIndex, row) in rows.enumerated() {
            let rowNumber = String(rowIndex + 1)
            xml += #"<row r="\#(rowNumber)">"#

            // A cell needs its reference only when an empty cell before it was left out.
            var previousWritten = -1
            let style = rowIndex == 0 ? #" s="1""# : ""

            for (columnIndex, value) in row.enumerated() where !value.isEmpty {
                if columnIndex == previousWritten + 1 {
                    xml += #"<c\#(style) t="inlineStr">"#
                } else {
                    xml += #"<c r="\#(columnNames[columnIndex])\#(rowNumber)"\#(style) t="inlineStr">"#
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
