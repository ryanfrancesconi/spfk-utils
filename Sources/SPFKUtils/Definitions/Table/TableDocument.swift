// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// The spreadsheet formats read by `TableDocument.read(contentsOf:)` and written by
/// `CSVBuilder` and `XLSXWriter`.
public enum TableFileFormat: String, Codable, CaseIterable, Sendable {
    case csv
    case tsv
    case xlsx

    public var fileExtension: String { rawValue }

    /// The field delimiter, or `nil` for a format that has none.
    public var delimiter: Character? {
        switch self {
        case .csv: ","
        case .tsv: "\t"
        case .xlsx: nil
        }
    }
}

/// One worksheet, or the whole of a delimited text file.
public struct TableSheet: Equatable, Sendable {
    public var name: String

    /// `rows[0]` is the header row. Rows shorter than the header are padded with empty cells.
    public var rows: [[String]]

    /// Indexes into `rows` of rows holding more cells than the header. Their cells are kept.
    public var overlongRows: [Int]

    public init(name: String, rows: [[String]], overlongRows: [Int] = []) {
        self.name = name
        self.rows = rows
        self.overlongRows = overlongRows
    }

    /// Pads short rows to the header's width, records long ones, and drops trailing rows whose
    /// cells are all empty.
    init(name: String, normalizing rawRows: [[String]]) {
        var rows = rawRows

        while let last = rows.last, last.allSatisfy(\.isEmpty) {
            rows.removeLast()
        }

        let width = rows.first?.count ?? 0
        var overlong = [Int]()

        for index in rows.indices {
            let count = rows[index].count

            if count < width {
                rows[index].append(contentsOf: repeatElement("", count: width - count))
            } else if count > width {
                overlong.append(index)
            }
        }

        self.init(name: name, rows: rows, overlongRows: overlong)
    }
}

/// A parsed spreadsheet: its sheets, plus what was detected while reading delimited text.
public struct TableDocument: Equatable, Sendable {
    public var sheets: [TableSheet]

    /// The text encoding a delimited file was decoded with. `nil` for XLSX.
    public var encoding: String.Encoding?

    /// The field delimiter of a delimited file. `nil` for XLSX.
    public var delimiter: Character?

    public init(sheets: [TableSheet], encoding: String.Encoding? = nil, delimiter: Character? = nil) {
        self.sheets = sheets
        self.encoding = encoding
        self.delimiter = delimiter
    }

    /// Reads XLSX when the file starts with a zip signature and delimited text otherwise, so the
    /// extension plays no part.
    public static func read(
        contentsOf url: URL,
        encoding: String.Encoding? = nil,
        delimiter: Character? = nil
    ) throws -> TableDocument {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)

        if data.starts(with: ZipArchive.localHeaderSignatureBytes) {
            return try XLSXReader.read(data: data)
        }

        return try CSVParser.parse(data, encoding: encoding, delimiter: delimiter)
    }
}
