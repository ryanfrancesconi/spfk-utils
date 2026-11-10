// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

extension XLSXReader {
    private enum Name {
        static let relationship = Array("Relationship".utf8)
        static let sheet = Array("sheet".utf8)
        static let si = Array("si".utf8)
        static let t = Array("t".utf8)
        static let rPh = Array("rPh".utf8)
        static let row = Array("row".utf8)
        static let c = Array("c".utf8)
        static let v = Array("v".utf8)
        static let `is` = Array("is".utf8)
        static let r = Array("r".utf8)
        static let id = Array("id".utf8)
        static let capitalId = Array("Id".utf8)
        static let target = Array("Target".utf8)
        static let type = Array("Type".utf8)
        static let name = Array("name".utf8)
    }

    /// `xl/_rels/workbook.xml.rels`: each relationship's ID, target part and type.
    static func relationshipItems(_ scanner: inout XMLScanner) throws -> [(id: String, target: String, type: String)] {
        var items = [(id: String, target: String, type: String)]()

        while let token = try scanner.next() {
            guard case let .start(name, attributes) = token, scanner.isName(name, Name.relationship),
                  let id = scanner.attribute(Name.capitalId, in: attributes),
                  let target = scanner.attribute(Name.target, in: attributes)
            else { continue }

            items.append((id, target, scanner.attribute(Name.type, in: attributes) ?? ""))
        }

        return items
    }

    /// `xl/workbook.xml`: each sheet's name and relationship ID, in workbook order.
    static func workbookSheets(_ scanner: inout XMLScanner) throws -> [(name: String, relationshipID: String)] {
        var sheets = [(name: String, relationshipID: String)]()

        while let token = try scanner.next() {
            guard case let .start(name, attributes) = token, scanner.isName(name, Name.sheet),
                  let relationshipID = scanner.attribute(Name.id, in: attributes)
            else { continue }

            sheets.append((scanner.attribute(Name.name, in: attributes) ?? "", relationshipID))
        }

        return sheets
    }

    /// `xl/sharedStrings.xml`: each `<si>` as one string, its rich-text runs joined and its
    /// phonetic runs left out.
    static func sharedStringItems(_ scanner: inout XMLScanner) throws -> [String] {
        var strings = [String]()
        var current = ""
        var inText = false
        var phoneticDepth = 0

        while let token = try scanner.next() {
            switch token {
            case let .start(name, _):
                if scanner.isName(name, Name.t) {
                    inText = phoneticDepth == 0
                } else if scanner.isName(name, Name.si) {
                    current = ""
                } else if scanner.isName(name, Name.rPh) {
                    phoneticDepth += 1
                }

            case let .end(name):
                if scanner.isName(name, Name.t) {
                    inText = false
                } else if scanner.isName(name, Name.si) {
                    strings.append(XLSXText.decodeEscapes(current))
                } else if scanner.isName(name, Name.rPh) {
                    phoneticDepth -= 1
                }

            case let .text(range):
                if inText { current += scanner.text(range) }

            case let .cdata(range):
                if inText { current += String(decoding: scanner.bytes[range], as: UTF8.self) }
            }
        }

        return strings
    }

    /// A worksheet's cells as rows of text. Rows and cells skipped by their `r` reference are
    /// filled with empty strings.
    static func worksheetRows(_ scanner: inout XMLScanner, sharedStrings: [String]) throws -> [[String]] {
        var rows = [[String]]()
        var row = [String]()
        var rowNumber = 0
        var column = 0
        var cellType = ""
        var value = ""
        var collecting = false
        var inInlineString = false
        var phoneticDepth = 0

        while let token = try scanner.next() {
            switch token {
            case let .start(name, attributes):
                if scanner.isName(name, Name.c) {
                    if let reference = scanner.attribute(Name.r, in: attributes),
                       let referenced = XLSXText.parseReference(reference).column {
                        column = referenced
                    }
                    cellType = scanner.attribute(Name.t, in: attributes) ?? "n"
                    value = ""
                } else if scanner.isName(name, Name.v) {
                    collecting = true
                } else if scanner.isName(name, Name.t) {
                    collecting = inInlineString && phoneticDepth == 0
                } else if scanner.isName(name, Name.is) {
                    inInlineString = true
                } else if scanner.isName(name, Name.rPh) {
                    phoneticDepth += 1
                } else if scanner.isName(name, Name.row) {
                    let number = scanner.attribute(Name.r, in: attributes).flatMap { Int($0) } ?? rowNumber + 1

                    while rowNumber + 1 < number {
                        rows.append([])
                        rowNumber += 1
                    }

                    rowNumber = number
                    row = []
                    column = 0
                }

            case let .end(name):
                if scanner.isName(name, Name.c) {
                    if row.count < column {
                        row.append(contentsOf: repeatElement("", count: column - row.count))
                    }

                    let text = cellText(type: cellType, value: value, sharedStrings: sharedStrings)

                    if column < row.count {
                        row[column] = text
                    } else {
                        row.append(text)
                    }

                    column += 1
                } else if scanner.isName(name, Name.v) || scanner.isName(name, Name.t) {
                    collecting = false
                } else if scanner.isName(name, Name.is) {
                    inInlineString = false
                } else if scanner.isName(name, Name.rPh) {
                    phoneticDepth -= 1
                } else if scanner.isName(name, Name.row) {
                    rows.append(row)
                }

            case let .text(range):
                if collecting { value += scanner.text(range) }

            case let .cdata(range):
                if collecting { value += String(decoding: scanner.bytes[range], as: UTF8.self) }
            }
        }

        return rows
    }

    private static func cellText(type: String, value: String, sharedStrings: [String]) -> String {
        switch type {
        case "s":
            guard let index = Int(value), sharedStrings.indices.contains(index) else { return "" }
            return sharedStrings[index]
        case "inlineStr", "str":
            return XLSXText.decodeEscapes(value)
        case "b":
            return value == "1" ? "TRUE" : value == "0" ? "FALSE" : value
        case "n":
            return numberText(value)
        default:
            return value
        }
    }

    /// The shortest text for a stored number: an integral value has no fraction.
    static func numberText(_ raw: String) -> String {
        guard let number = Double(raw), number.isFinite else { return raw }

        if number == number.rounded(), abs(number) < 1e15 {
            return String(Int64(number))
        }

        return String(number)
    }
}
