// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// A typed sort value used to compare table rows across columns of different data types.
public enum SortValue: Hashable, Sendable {
    case string(String)
    case double(Double)
    case integer(Int)
}

extension SortValue: Comparable {
    /// Three-way ordering. A sort that has to tell *equal* from *ordered* — to break ties on
    /// something else — gets both from one call; `<` alone has to be asked twice, and for
    /// `.string` each ask is a separate `localizedStandardCompare`.
    public func compare(_ other: SortValue) -> ComparisonResult {
        switch (self, other) {
        case let (.string(a), .string(b)):
            a.localizedStandardCompare(b)
        case let (.double(a), .double(b)):
            Self.order(a, b)
        case let (.integer(a), .integer(b)):
            Self.order(a, b)
        case let (.integer(a), .double(b)):
            Self.order(Double(a), b)
        case let (.double(a), .integer(b)):
            Self.order(a, Double(b))
        case (.string, .double), (.string, .integer):
            // Numerics sort before strings in cross-type comparisons
            .orderedDescending
        case (.double, .string), (.integer, .string):
            .orderedAscending
        }
    }

    private static func order<T: Comparable>(_ a: T, _ b: T) -> ComparisonResult {
        if a < b { return .orderedAscending }
        if b < a { return .orderedDescending }
        return .orderedSame
    }

    public static func < (lhs: SortValue, rhs: SortValue) -> Bool {
        lhs.compare(rhs) == .orderedAscending
    }
}
