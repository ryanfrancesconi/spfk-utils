// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// A pull tokenizer over well-formed XML bytes, for the regular parts of an `.xlsx` package.
///
/// Tokens carry byte ranges, so a consumer decodes only the text it keeps. A self-closing element
/// is reported as a start followed by an end. Prolog, comments, processing instructions and
/// doctype declarations are skipped; names compare by local name, ignoring any prefix.
struct XMLScanner {
    enum Token {
        case start(name: Range<Int>, attributes: Range<Int>)
        case end(name: Range<Int>)
        case text(Range<Int>)
        case cdata(Range<Int>)
    }

    struct Malformed: Error {
        let offset: Int
    }

    let bytes: [UInt8]
    private var index = 0
    private var pendingEnd: Range<Int>?

    init(_ data: Data) {
        bytes = [UInt8](data)
    }

    // MARK: - Tokens

    mutating func next() throws -> Token? {
        if let name = pendingEnd {
            pendingEnd = nil
            return .end(name: name)
        }

        let count = bytes.count

        while index < count {
            guard bytes[index] == .lessThan else {
                let start = index
                while index < count, bytes[index] != .lessThan { index += 1 }
                return .text(start ..< index)
            }

            guard index + 1 < count else { throw Malformed(offset: index) }

            switch bytes[index + 1] {
            case UInt8(ascii: "?"):
                index = try position(after: Array("?>".utf8), from: index + 2)

            case UInt8(ascii: "!"):
                if hasPrefix(Array("<!--".utf8), at: index) {
                    index = try position(after: Array("-->".utf8), from: index + 4)
                } else if hasPrefix(Array("<![CDATA[".utf8), at: index) {
                    let start = index + 9
                    index = try position(after: Array("]]>".utf8), from: start)
                    return .cdata(start ..< index - 3)
                } else {
                    index = try position(after: [.greaterThan], from: index + 2)
                }

            case UInt8(ascii: "/"):
                let nameStart = index + 2
                var nameEnd = nameStart
                while nameEnd < count, !isNameEnd(bytes[nameEnd]) { nameEnd += 1 }
                index = try position(after: [.greaterThan], from: nameEnd)
                return .end(name: nameStart ..< nameEnd)

            default:
                let nameStart = index + 1
                var cursor = nameStart
                while cursor < count, !isNameEnd(bytes[cursor]) { cursor += 1 }
                let nameEnd = cursor

                var quote: UInt8?
                while cursor < count {
                    let byte = bytes[cursor]
                    if let open = quote {
                        if byte == open { quote = nil }
                    } else if byte == .doubleQuote || byte == .singleQuote {
                        quote = byte
                    } else if byte == .greaterThan {
                        break
                    }
                    cursor += 1
                }

                guard cursor < count else { throw Malformed(offset: index) }

                let selfClosing = bytes[cursor - 1] == .slash
                let attributes = nameEnd ..< (selfClosing ? cursor - 1 : cursor)
                index = cursor + 1

                if selfClosing { pendingEnd = nameStart ..< nameEnd }
                return .start(name: nameStart ..< nameEnd, attributes: attributes)
            }
        }

        return nil
    }

    // MARK: - Names and attributes

    /// Whether the local part of `name` (after any `prefix:`) is `local`.
    func isName(_ name: Range<Int>, _ local: [UInt8]) -> Bool {
        guard name.count >= local.count else { return false }

        let localStart = name.upperBound - local.count

        guard localStart == name.lowerBound || bytes[localStart - 1] == .colon else { return false }
        return bytes[localStart ..< name.upperBound].elementsEqual(local)
    }

    /// The decoded value of the attribute whose local name is `local`.
    func attribute(_ local: [UInt8], in range: Range<Int>) -> String? {
        var cursor = range.lowerBound

        while cursor < range.upperBound {
            while cursor < range.upperBound, isWhitespace(bytes[cursor]) { cursor += 1 }

            let nameStart = cursor
            while cursor < range.upperBound, bytes[cursor] != .equals, !isWhitespace(bytes[cursor]) { cursor += 1 }
            let nameRange = nameStart ..< cursor

            while cursor < range.upperBound, bytes[cursor] != .doubleQuote, bytes[cursor] != .singleQuote { cursor += 1 }
            guard cursor < range.upperBound else { return nil }

            let quote = bytes[cursor]
            let valueStart = cursor + 1
            cursor = valueStart
            while cursor < range.upperBound, bytes[cursor] != quote { cursor += 1 }
            let valueRange = valueStart ..< min(cursor, range.upperBound)
            cursor += 1

            if !nameRange.isEmpty, isName(nameRange, local) {
                return text(valueRange)
            }
        }

        return nil
    }

    // MARK: - Text

    /// The bytes in `range` with entity and character references resolved and line ends
    /// normalized to LF, as an XML parser reports them.
    func text(_ range: Range<Int>) -> String {
        let slice = bytes[range]

        guard slice.contains(where: { $0 == .ampersand || $0 == .carriageReturn }) else {
            return String(decoding: slice, as: UTF8.self)
        }

        var output = [UInt8]()
        output.reserveCapacity(slice.count)
        var cursor = range.lowerBound

        while cursor < range.upperBound {
            let byte = bytes[cursor]

            if byte == .carriageReturn {
                output.append(.lineFeed)
                cursor += cursor + 1 < range.upperBound && bytes[cursor + 1] == .lineFeed ? 2 : 1
            } else if byte == .ampersand,
                      let semicolon = bytes[cursor ..< min(range.upperBound, cursor + 12)].firstIndex(of: .semicolon),
                      let resolved = resolveReference(cursor + 1 ..< semicolon) {
                output += resolved
                cursor = semicolon + 1
            } else {
                output.append(byte)
                cursor += 1
            }
        }

        return String(decoding: output, as: UTF8.self)
    }

    private func resolveReference(_ range: Range<Int>) -> [UInt8]? {
        let name = bytes[range]

        switch String(decoding: name, as: UTF8.self) {
        case "amp": return [.ampersand]
        case "lt": return [.lessThan]
        case "gt": return [.greaterThan]
        case "quot": return [.doubleQuote]
        case "apos": return [.singleQuote]
        default: break
        }

        guard name.first == UInt8(ascii: "#") else { return nil }

        let digits = String(decoding: name.dropFirst(), as: UTF8.self)
        let value = digits.first == "x" ? UInt32(digits.dropFirst(), radix: 16) : UInt32(digits, radix: 10)

        guard let value, let scalar = Unicode.Scalar(value) else { return nil }
        return Array(String(Character(scalar)).utf8)
    }

    // MARK: - Bytes

    private func hasPrefix(_ prefix: [UInt8], at offset: Int) -> Bool {
        offset + prefix.count <= bytes.count && bytes[offset ..< offset + prefix.count].elementsEqual(prefix)
    }

    /// The index just past the next occurrence of `terminator` at or after `start`.
    private func position(after terminator: [UInt8], from start: Int) throws -> Int {
        var cursor = start

        while cursor + terminator.count <= bytes.count {
            if bytes[cursor] == terminator[0], hasPrefix(terminator, at: cursor) {
                return cursor + terminator.count
            }
            cursor += 1
        }

        throw Malformed(offset: start)
    }

    private func isWhitespace(_ byte: UInt8) -> Bool {
        byte == .space || byte == .tab || byte == .lineFeed || byte == .carriageReturn
    }

    private func isNameEnd(_ byte: UInt8) -> Bool {
        isWhitespace(byte) || byte == .greaterThan || byte == .slash
    }
}

extension UInt8 {
    fileprivate static let lessThan = UInt8(ascii: "<")
    fileprivate static let greaterThan = UInt8(ascii: ">")
    fileprivate static let slash = UInt8(ascii: "/")
    fileprivate static let colon = UInt8(ascii: ":")
    fileprivate static let equals = UInt8(ascii: "=")
    fileprivate static let semicolon = UInt8(ascii: ";")
    fileprivate static let ampersand = UInt8(ascii: "&")
    fileprivate static let doubleQuote = UInt8(ascii: "\"")
    fileprivate static let singleQuote = UInt8(ascii: "'")
    fileprivate static let space = UInt8(ascii: " ")
    fileprivate static let tab = UInt8(ascii: "\t")
    fileprivate static let lineFeed = UInt8(ascii: "\n")
    fileprivate static let carriageReturn = UInt8(ascii: "\r")
}
