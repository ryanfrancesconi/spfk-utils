// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// How an export names its files, before the extension and before ``BatchOutputClaims`` numbers
/// any that collide.
public struct ExportNaming: Sendable, Hashable, Codable {
    public enum Scheme: String, Sendable, Hashable, Codable, CaseIterable {
        case fileName
        case title
        case sequential
        case collectionNameWithNumber
    }

    public var scheme: Scheme

    /// Leads each name under ``Scheme/sequential``.
    public var prefix: String

    /// Between a name and its number.
    public static let separator = " "

    /// Leaves room under the 255-byte file name limit for an extension and a collision number.
    static let maximumByteCount = 240

    public init(scheme: Scheme = .fileName, prefix: String = "") {
        self.scheme = scheme
        self.prefix = prefix
    }

    /// One base name per item, in the order given, which is the order numbers are assigned in.
    ///
    /// An empty title falls back to the file name. Numbers count from 1, padded to the width of the
    /// count so the names sort in order.
    public func baseNames<Item>(
        for items: [Item],
        fileName: (Item) -> String,
        title: (Item) -> String?,
        collectionName: String
    ) -> [String] {
        let width = String(items.count).count

        return items.enumerated().map { offset, item in
            let number = String(repeating: "0", count: max(0, width - String(offset + 1).count)) + String(offset + 1)
            let fallback = Self.sanitized(fileName(item))

            let name: String = switch scheme {
            case .fileName: fallback
            case .title: Self.sanitized(title(item) ?? "")
            case .sequential: Self.numbered(prefix, number)
            case .collectionNameWithNumber: Self.numbered(collectionName, number)
            }

            return name.isEmpty ? fallback : name
        }
    }

    private static func numbered(_ name: String, _ number: String) -> String {
        let name = sanitized(name)
        return name.isEmpty ? number : name + separator + number
    }

    /// Trims whitespace and leading dots, which hide a file, replaces `/` and `:` with `-`, and
    /// shortens to ``maximumByteCount`` on whole characters.
    static func sanitized(_ name: String) -> String {
        let cleaned = String(name.trimmingCharacters(in: .whitespacesAndNewlines).drop { $0 == "." })
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")

        var byteCount = 0
        let kept = cleaned.prefix {
            byteCount += $0.utf8.count
            return byteCount <= maximumByteCount
        }

        return String(kept).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
