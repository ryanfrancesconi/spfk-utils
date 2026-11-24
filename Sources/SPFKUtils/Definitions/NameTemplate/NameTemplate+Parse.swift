// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

extension NameTemplate {
    /// The parsed template: literal text, folder separators, tokens and optional sections.
    indirect enum Part: Sendable {
        case literal(String)
        case slash
        case token(Token)
        case section([Part])
    }

    struct Token: Sendable {
        enum Alternative: Sendable {
            case literal(String)
            case value(name: String, argument: String?)
        }

        struct Modifier: Sendable {
            var name: String
            var argument: String?
        }

        var alternatives: [Alternative]
        var modifiers: [Modifier]
    }

    /// Whether any token reads the value `name`, in any alternative.
    public func reads(_ name: String) -> Bool {
        func reads(_ parts: [Part]) -> Bool {
            parts.contains { part in
                switch part {
                case .literal, .slash: false
                case let .section(inner): reads(inner)
                case let .token(token):
                    token.alternatives.contains {
                        guard case let .value(valueName, _) = $0 else { return false }
                        return valueName == name
                    }
                }
            }
        }

        return reads(parts)
    }

    // MARK: - Lexing

    static func lex(_ source: String) -> [Lexeme] {
        let characters = Array(source)
        var lexemes: [Lexeme] = []
        var text = ""
        var i = 0

        func flush() {
            if !text.isEmpty { lexemes.append(.text(text)) }
            text = ""
        }

        while i < characters.count {
            let character = characters[i]
            let next = i + 1 < characters.count ? characters[i + 1] : nil

            if (character == "{" || character == "}") && next == character {
                text += String(repeating: character, count: 2)
                i += 2
            } else if character == "{", let end = tokenEnd(in: characters, openingAt: i) {
                flush()
                lexemes.append(.token(String(characters[i ... end])))
                i = end + 1
            } else {
                text.append(character)
                i += 1
            }
        }

        flush()
        return lexemes
    }

    /// The closing brace of a token opened at `start`: the first `}` outside double quotes, before
    /// any other `{`. Nil for an unclosed or empty token, which is then literal text.
    private static func tokenEnd(in characters: [Character], openingAt start: Int) -> Int? {
        var inQuote = false

        for j in (start + 1) ..< characters.count {
            switch characters[j] {
            case "\"": inQuote.toggle()
            case "}" where !inQuote: return j > start + 1 ? j : nil
            case "{" where !inQuote: return nil
            default: break
            }
        }

        return nil
    }

    // MARK: - Parts

    fileprivate enum Item {
        case literal(String)
        case slash
        case open
        case close
        case token(Token)
    }

    static func parts(of lexemes: [Lexeme]) -> [Part] {
        var items: [Item] = []

        for lexeme in lexemes {
            switch lexeme {
            case let .token(source):
                items.append(.token(Token(source: source)))

            case let .text(source):
                for character in unescaped(source) {
                    switch character {
                    case "/": items.append(.slash)
                    case "[": items.append(.open)
                    case "]": items.append(.close)
                    default:
                        if case let .literal(text) = items.last {
                            items[items.count - 1] = .literal(text + String(character))
                        } else {
                            items.append(.literal(String(character)))
                        }
                    }
                }
            }
        }

        return sections(in: items)
    }

    /// Pairs each `[` with the next `]`, making a section of what lies between when a token is
    /// inside. Any other bracket is literal.
    private static func sections(in items: [Item]) -> [Part] {
        var parts: [Part] = []
        var i = 0

        while i < items.count {
            switch items[i] {
            case let .literal(text): parts.append(.literal(text))
            case .slash: parts.append(.slash)
            case let .token(token): parts.append(.token(token))
            case .close: parts.append(.literal("]"))

            case .open:
                let rest = items[(i + 1)...]
                let end = rest.firstIndex {
                    switch $0 {
                    case .open, .close: true
                    default: false
                    }
                }

                if let end, case .close = items[end], rest[..<end].contains(where: \.isToken) {
                    parts.append(.section(rest[..<end].map(\.part)))
                    i = end
                } else {
                    parts.append(.literal("["))
                }
            }

            i += 1
        }

        return parts
    }

    /// Text with `{{` and `}}` read as single braces, paired left to right as the lexer pairs them.
    static func unescaped(_ source: String) -> String {
        guard source.contains("{{") || source.contains("}}") else { return source }

        let characters = Array(source)
        var result = ""
        var i = 0

        while i < characters.count {
            let character = characters[i]
            result.append(character)
            let isPair = (character == "{" || character == "}") && i + 1 < characters.count && characters[i + 1] == character
            i += isPair ? 2 : 1
        }

        return result
    }
}

extension NameTemplate.Item {
    fileprivate var isToken: Bool {
        if case .token = self { return true }
        return false
    }

    /// Only called inside a section, which holds no brackets.
    fileprivate var part: NameTemplate.Part {
        switch self {
        case let .literal(text): .literal(text)
        case .slash: .slash
        case let .token(token): .token(token)
        case .open: .literal("[")
        case .close: .literal("]")
        }
    }
}

// MARK: - Tokens

extension NameTemplate.Token {
    /// Parses `{name:argument?alternative|modifier:argument}` from its source, braces included.
    init(source: String) {
        let body = String(source.dropFirst().dropLast())
        let pieces = Self.split(body, on: "|")
        let chain = Self.split(pieces.first ?? "", on: "?")

        alternatives = chain.map { alternative in
            if alternative.hasPrefix("\"") {
                var literal = alternative.dropFirst()
                if literal.hasSuffix("\"") { literal = literal.dropLast() }
                return .literal(String(literal))
            }

            let (name, argument) = Self.nameAndArgument(alternative)
            return .value(name: name, argument: argument)
        }

        modifiers = pieces.dropFirst().map {
            let (name, argument) = Self.nameAndArgument($0)
            return Modifier(name: name, argument: argument)
        }
    }

    private static func nameAndArgument(_ text: String) -> (String, String?) {
        guard let colon = text.firstIndex(of: ":") else { return (text, nil) }
        return (String(text[..<colon]), String(text[text.index(after: colon)...]))
    }

    /// `text` split on `separator` where it is outside double quotes.
    private static func split(_ text: String, on separator: Character) -> [String] {
        var pieces: [String] = []
        var current = ""
        var inQuote = false

        for character in text {
            if character == "\"" { inQuote.toggle() }

            if character == separator && !inQuote {
                pieces.append(current)
                current = ""
            } else {
                current.append(character)
            }
        }

        pieces.append(current)
        return pieces
    }
}
