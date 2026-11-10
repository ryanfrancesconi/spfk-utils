// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// Builds RFC 4180 delimited text from a header row and a per-row value provider.
public enum CSVBuilder {
    /// - Parameters:
    ///   - columns: The header row.
    ///   - rows: The source data, one CSV row per element.
    ///   - delimiter: The field separator: `","` for CSV, `"\t"` for TSV.
    ///   - rowValues: Returns the raw (unescaped) column values for one row, in `columns` order.
    ///     Do any per-row setup/caching inside this closure, not per-column.
    public static func build<Row>(
        columns: [String],
        rows: [Row],
        delimiter: Character = ",",
        rowValues: (Row) -> [String]
    ) -> String {
        let separator = String(delimiter)

        func line(_ fields: [String]) -> String {
            fields.map { escapeField($0, delimiter: delimiter) }.joined(separator: separator)
        }

        var lines = [line(columns)]
        for row in rows {
            lines.append(line(rowValues(row)))
        }
        return lines.joined(separator: "\r\n")
    }

    /// RFC 4180 field escaping: quote fields containing the delimiter, quotes, or newlines.
    ///
    /// The newline test is per-`Character` rather than a substring search for `"\n"`: CRLF is a
    /// single grapheme cluster in Swift and matches neither half on its own.
    public static func escapeField(_ field: String, delimiter: Character = ",") -> String {
        let needsQuoting = field.contains(delimiter) || field.contains("\"") ||
            field.contains(where: \.isNewline)

        guard needsQuoting else { return field }

        let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
