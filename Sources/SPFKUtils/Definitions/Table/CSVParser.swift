// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

public enum CSVParserError: Error, Equatable, LocalizedError {
    case undecodable(String.Encoding)
    case unsupportedDelimiter(Character)
    /// `row` is 1-based, counting records rather than lines.
    case unterminatedQuote(row: Int)

    public var errorDescription: String? {
        switch self {
        case let .undecodable(encoding):
            "The file is not valid \(String.localizedName(of: encoding)) text."
        case let .unsupportedDelimiter(delimiter):
            "\"\(delimiter)\" can't be used as a field delimiter."
        case let .unterminatedQuote(row):
            "Row \(row) opens a quoted field that is never closed."
        }
    }
}

/// Reads RFC 4180 delimited text, detecting its encoding and delimiter when not given.
///
/// Lenient where Excel is: a quote inside an unquoted field is literal, and text after a closing
/// quote is appended to the field.
public enum CSVParser {
    /// The delimiters `sniffDelimiter` chooses between, in tie-break order.
    public static let sniffedDelimiters: [Character] = ["\t", ",", ";"]

    public static func parse(
        _ data: Data,
        encoding: String.Encoding? = nil,
        delimiter: Character? = nil
    ) throws -> TableDocument {
        var (text, detectedEncoding) = try decode(data, encoding: encoding)

        let resolvedDelimiter = delimiter ?? sniffDelimiter(text)

        guard let delimiterByte = resolvedDelimiter.asciiValue,
              ![quote, cr, lf].contains(delimiterByte)
        else {
            throw CSVParserError.unsupportedDelimiter(resolvedDelimiter)
        }

        let rows = try text.withUTF8 { try parseRows($0, delimiter: delimiterByte) }

        return TableDocument(
            sheets: [TableSheet(name: "", normalizing: rows)],
            encoding: detectedEncoding,
            delimiter: resolvedDelimiter
        )
    }

    // MARK: - Encoding

    /// Decodes with `encoding` when given. Otherwise: a byte order mark, then strict UTF-8, then
    /// Windows-1252, then ISO Latin-1, which accepts any bytes.
    public static func decode(_ data: Data, encoding: String.Encoding?) throws -> (String, String.Encoding) {
        if let encoding {
            guard let text = String(data: data, encoding: encoding) else {
                throw CSVParserError.undecodable(encoding)
            }
            return (droppingByteOrderMark(text), encoding)
        }

        let boms: [([UInt8], String.Encoding)] = [
            ([0xEF, 0xBB, 0xBF], .utf8),
            ([0xFF, 0xFE], .utf16LittleEndian),
            ([0xFE, 0xFF], .utf16BigEndian),
        ]

        for (bom, bomEncoding) in boms where data.starts(with: bom) {
            guard let text = String(data: data.dropFirst(bom.count), encoding: bomEncoding) else {
                throw CSVParserError.undecodable(bomEncoding)
            }
            return (text, bomEncoding)
        }

        for candidate: String.Encoding in [.utf8, .windowsCP1252, .isoLatin1] {
            if let text = String(data: data, encoding: candidate) {
                return (text, candidate)
            }
        }

        throw CSVParserError.undecodable(.isoLatin1)
    }

    private static func droppingByteOrderMark(_ text: String) -> String {
        guard text.unicodeScalars.first?.value == 0xFEFF else { return text }
        return String(text.unicodeScalars.dropFirst())
    }

    // MARK: - Delimiter

    /// Counts each candidate outside quotes in the first record; the most frequent wins, ties go
    /// to the earlier entry in `sniffedDelimiters`, and a record with none of them gives comma.
    public static func sniffDelimiter(_ text: String) -> Character {
        var counts = [UInt8: Int]()
        var inQuotes = false

        for byte in text.utf8 {
            if byte == quote {
                inQuotes.toggle()
            } else if !inQuotes {
                if byte == cr || byte == lf { break }
                counts[byte, default: 0] += 1
            }
        }

        var best: Character = ","
        var bestCount = 0

        for candidate in sniffedDelimiters {
            guard let byte = candidate.asciiValue, let count = counts[byte], count > bestCount else { continue }
            best = candidate
            bestCount = count
        }

        return best
    }

    // MARK: - Records

    private static let quote = UInt8(ascii: "\"")
    private static let cr = UInt8(ascii: "\r")
    private static let lf = UInt8(ascii: "\n")

    private static func parseRows(_ bytes: UnsafeBufferPointer<UInt8>, delimiter: UInt8) throws -> [[String]] {
        let count = bytes.count
        var rows = [[String]]()
        var row = [String]()
        var index = 0

        func isFieldEnd(_ byte: UInt8) -> Bool {
            byte == delimiter || byte == cr || byte == lf
        }

        func string(_ start: Int, _ end: Int) -> String {
            String(decoding: UnsafeBufferPointer(rebasing: bytes[start ..< end]), as: UTF8.self)
        }

        while true {
            var field: String

            if index < count, bytes[index] == quote {
                index += 1
                var segmentStart = index
                var unescaped: [UInt8]?

                while index < count {
                    if bytes[index] == quote {
                        guard index + 1 < count, bytes[index + 1] == quote else { break }
                        // Keep one of the two quotes.
                        unescaped = (unescaped ?? []) + bytes[segmentStart ... index]
                        index += 2
                        segmentStart = index
                    } else {
                        index += 1
                    }
                }

                guard index < count else {
                    throw CSVParserError.unterminatedQuote(row: rows.count + 1)
                }

                if let unescaped {
                    field = String(decoding: unescaped + bytes[segmentStart ..< index], as: UTF8.self)
                } else {
                    field = string(segmentStart, index)
                }

                index += 1

                let tailStart = index
                while index < count, !isFieldEnd(bytes[index]) { index += 1 }
                if index > tailStart { field += string(tailStart, index) }
            } else {
                let start = index
                while index < count, !isFieldEnd(bytes[index]) { index += 1 }
                field = string(start, index)
            }

            row.append(field)

            guard index < count else {
                rows.append(row)
                break
            }

            if bytes[index] == delimiter {
                index += 1
                continue
            }

            if bytes[index] == cr, index + 1 < count, bytes[index + 1] == lf {
                index += 2
            } else {
                index += 1
            }

            rows.append(row)
            row = []

            if index >= count { break }
        }

        return rows
    }
}
