// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// Builds RFC 4180 CSV text from a header row and a per-row value provider.
public enum CSVBuilder {
    /// - Parameters:
    ///   - columns: The header row.
    ///   - rows: The source data, one CSV row per element.
    ///   - rowValues: Returns the raw (unescaped) column values for one row, in `columns` order.
    ///     Do any per-row setup/caching inside this closure, not per-column.
    public static func build<Row>(
        columns: [String],
        rows: [Row],
        rowValues: (Row) -> [String]
    ) -> String {
        var lines = [columns.map(escapeField).joined(separator: ",")]
        for row in rows {
            lines.append(rowValues(row).map(escapeField).joined(separator: ","))
        }
        return lines.joined(separator: "\r\n")
    }

    /// RFC 4180 CSV field escaping: quote fields containing commas, quotes, or newlines.
    public static func escapeField(_ field: String) -> String {
        let needsQuoting = field.contains(",") || field.contains("\"") ||
            field.contains("\n") || field.contains("\r")

        guard needsQuoting else { return field }

        let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
