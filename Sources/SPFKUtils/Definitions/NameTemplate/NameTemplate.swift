// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// A file name, or a folder path, written as text with `{token}` placeholders.
///
/// `{name}`, `{date:YYYY-MM-DD}` and `{seq:3}` substitute a file's values; `{title?name}` falls back
/// to the first non-empty alternative, `{title|upper}` applies modifiers, and `[_{creator}]` is
/// dropped whole when a token inside is empty. Malformed input is literal text, never an error.
public struct NameTemplate: Sendable, Hashable, Codable {
    public static let currentVersion = 1

    public let source: String

    /// The source split into text and tokens, holding exact source text.
    public let lexemes: [Lexeme]

    let parts: [Part]

    public init(_ source: String) {
        self.source = source
        lexemes = Self.lex(source)
        parts = Self.parts(of: lexemes)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.source == rhs.source
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(source)
    }

    public init(from decoder: Decoder) throws {
        try self.init(decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(source)
    }
}

extension NameTemplate {
    public enum Lexeme: Sendable, Hashable {
        case text(String)
        case token(String)

        public var source: String {
            switch self {
            case let .text(source), let .token(source): source
            }
        }
    }

    /// A token's value for one file.
    public enum Value: Sendable, Hashable {
        case text(String)
        case date(DateParts)
    }

    /// What one rendering knows besides the file's values.
    public struct RenderContext: Sendable, Hashable {
        /// 1-based position in the run.
        public var index: Int

        /// How many items the run names.
        public var count: Int

        /// `{collection}`'s value.
        public var collection: String

        public init(index: Int, count: Int, collection: String = "") {
            self.index = index
            self.count = count
            self.collection = collection
        }
    }

    /// `name`, `ext` and `folder` for a file.
    public static func urlValues(for url: URL) -> [String: Value] {
        [
            "name": .text(url.deletingPathExtension().lastPathComponent),
            "ext": .text(url.pathExtension),
            "folder": .text(url.deletingLastPathComponent().lastPathComponent),
        ]
    }
}
