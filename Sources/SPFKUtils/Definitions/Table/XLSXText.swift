// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// Text conventions shared by `XLSXReader` and `XLSXWriter`.
enum XLSXText {
    // MARK: - _xHHHH_ escapes

    /// Decodes the `_xHHHH_` escapes Office writes for characters XML cannot carry, including
    /// `_x000D_` for a carriage return. `_x005F_` is a literal underscore.
    static func decodeEscapes(_ text: String) -> String {
        guard containsEscapeStart(text) else { return text }

        let scalars = Array(text.unicodeScalars)
        var output = String.UnicodeScalarView()
        var index = 0

        while index < scalars.count {
            if let value = escapedValue(in: scalars, at: index), let scalar = Unicode.Scalar(value) {
                output.append(scalar)
                index += 7
            } else {
                output.append(scalars[index])
                index += 1
            }
        }

        return String(output)
    }

    /// Escapes a carriage return and every character XML 1.0 forbids as `_xHHHH_`, and protects
    /// text already shaped like an escape by writing its underscore as `_x005F_`. A raw CR would
    /// read back as LF, since XML parsers normalize line ends.
    static func encodeEscapes(_ text: String) -> String {
        guard text.utf8.contains(where: { $0 < 0x20 || $0 == UInt8(ascii: "_") || $0 == 0xEF }) else { return text }

        let scalars = Array(text.unicodeScalars)

        var output = String.UnicodeScalarView()

        for (index, scalar) in scalars.enumerated() {
            if needsEscape(scalar) || (scalar == "_" && escapedValue(in: scalars, at: index) != nil) {
                output.append(contentsOf: String(format: "_x%04X_", scalar.value).unicodeScalars)
            } else {
                output.append(scalar)
            }
        }

        return String(output)
    }

    private static func containsEscapeStart(_ text: String) -> Bool {
        var previousWasUnderscore = false

        for byte in text.utf8 {
            if previousWasUnderscore, byte == UInt8(ascii: "x") { return true }
            previousWasUnderscore = byte == UInt8(ascii: "_")
        }

        return false
    }

    private static func needsEscape(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x09, 0x0A: false
        case 0x0D: true
        case ..<0x20, 0xFFFE, 0xFFFF: true
        default: false
        }
    }

    /// The value of a `_xHHHH_` escape starting at `index`, if one does.
    private static func escapedValue(in scalars: [Unicode.Scalar], at index: Int) -> UInt32? {
        guard index + 7 <= scalars.count,
              scalars[index] == "_", scalars[index + 1] == "x", scalars[index + 6] == "_"
        else { return nil }

        var value: UInt32 = 0

        for scalar in scalars[index + 2 ..< index + 6] {
            guard let digit = Character(scalar).hexDigitValue else { return nil }
            value = value << 4 | UInt32(digit)
        }

        return value
    }

    // MARK: - XML

    static func escapeXML(_ text: String) -> String {
        let special: (UInt8) -> Bool = {
            $0 == UInt8(ascii: "&") || $0 == UInt8(ascii: "<") || $0 == UInt8(ascii: ">") || $0 == UInt8(ascii: "\"")
        }

        guard text.utf8.contains(where: special) else { return text }

        var output = ""
        output.reserveCapacity(text.utf8.count + 16)

        for character in text {
            switch character {
            case "&": output += "&amp;"
            case "<": output += "&lt;"
            case ">": output += "&gt;"
            case "\"": output += "&quot;"
            default: output.append(character)
            }
        }

        return output
    }

    // MARK: - Cell references

    /// `A` for 0, `Z` for 25, `AA` for 26.
    static func columnName(_ index: Int) -> String {
        var number = index + 1
        var letters = [Character]()

        while number > 0 {
            let remainder = (number - 1) % 26
            letters.append(Character(Unicode.Scalar(UInt8(65 + remainder))))
            number = (number - 1) / 26
        }

        return String(letters.reversed())
    }

    /// The zero-based column and one-based row of a reference such as `AB12`. Either is `nil`
    /// when the reference lacks that part.
    static func parseReference(_ reference: String) -> (column: Int?, row: Int?) {
        var column = 0
        var hasColumn = false
        var row = 0
        var hasRow = false

        for byte in reference.utf8 {
            switch byte {
            case UInt8(ascii: "A") ... UInt8(ascii: "Z"):
                column = column * 26 + Int(byte - UInt8(ascii: "A")) + 1
                hasColumn = true
            case UInt8(ascii: "a") ... UInt8(ascii: "z"):
                column = column * 26 + Int(byte - UInt8(ascii: "a")) + 1
                hasColumn = true
            case UInt8(ascii: "0") ... UInt8(ascii: "9"):
                row = row * 10 + Int(byte - UInt8(ascii: "0"))
                hasRow = true
            default:
                break
            }
        }

        return (hasColumn ? column - 1 : nil, hasRow ? row : nil)
    }
}
