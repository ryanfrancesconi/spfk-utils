// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

public enum XLSXReaderError: Error, Equatable, LocalizedError {
    case missingPart(String)
    case malformedXML(part: String, message: String)

    public var errorDescription: String? {
        switch self {
        case let .missingPart(part): "The workbook has no \"\(part)\"."
        case let .malformedXML(part, message): "\"\(part)\" could not be read: \(message)"
        }
    }
}

/// Reads every worksheet of an `.xlsx` workbook as text, in workbook order.
///
/// Values read as Excel displays them for text, booleans (`TRUE`/`FALSE`) and errors. A number
/// reads as its shortest form, so `2014` rather than `2014.0`. Styles are not read, so a
/// date-formatted cell reads as its serial number.
public enum XLSXReader {
    static let workbookPath = "xl/workbook.xml"
    static let workbookRelationshipsPath = "xl/_rels/workbook.xml.rels"

    public static func read(_ url: URL) throws -> TableDocument {
        try read(data: Data(contentsOf: url, options: .mappedIfSafe))
    }

    public static func read(data: Data) throws -> TableDocument {
        let entries = try ZipArchive.entries(of: data)

        func part(_ path: String) throws -> Data {
            guard let data = entries[path] else { throw XLSXReaderError.missingPart(path) }
            return data
        }

        let relationships = try scan(part(workbookRelationshipsPath), path: workbookRelationshipsPath, with: relationshipItems)
        let workbook = try scan(part(workbookPath), path: workbookPath, with: workbookSheets)

        let targets = Dictionary(
            relationships.map { ($0.id, resolve(target: $0.target)) },
            uniquingKeysWith: { first, _ in first }
        )

        var sharedStrings = [String]()

        if let sharedStringsPath = relationships
            .first(where: { $0.type.hasSuffix("/sharedStrings") })
            .map({ resolve(target: $0.target) }) {
            sharedStrings = try scan(part(sharedStringsPath), path: sharedStringsPath, with: sharedStringItems)
        }

        var sheets = [TableSheet]()

        for (name, relationshipID) in workbook {
            guard let path = targets[relationshipID] else { throw XLSXReaderError.missingPart(relationshipID) }

            let rows = try scan(part(path), path: path) { try worksheetRows(&$0, sharedStrings: sharedStrings) }
            sheets.append(TableSheet(name: name, normalizing: rows))
        }

        return TableDocument(sheets: sheets)
    }

    /// A relationship target is relative to `xl/`, or absolute within the package.
    private static func resolve(target: String) -> String {
        target.hasPrefix("/") ? String(target.dropFirst()) : "xl/" + target
    }

    private static func scan<Result>(
        _ data: Data,
        path: String,
        with body: (inout XMLScanner) throws -> Result
    ) throws -> Result {
        var scanner = XMLScanner(data)

        do {
            return try body(&scanner)
        } catch let error as XMLScanner.Malformed {
            throw XLSXReaderError.malformedXML(part: path, message: "malformed markup at byte \(error.offset)")
        }
    }
}
