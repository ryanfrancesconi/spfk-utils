// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// A typed sort value used to compare table rows across columns of different data types.
public enum SortValue: Hashable, Sendable {
    case string(String)
    case double(Double)
    case integer(Int)
}

extension SortValue: Comparable {
    public static func < (lhs: SortValue, rhs: SortValue) -> Bool {
        switch (lhs, rhs) {
        case let (.string(a), .string(b)):
            a.localizedStandardCompare(b) == .orderedAscending
        case let (.double(a), .double(b)):
            a < b
        case let (.integer(a), .integer(b)):
            a < b
        case let (.integer(a), .double(b)):
            Double(a) < b
        case let (.double(a), .integer(b)):
            a < Double(b)
        case (.string, .double), (.string, .integer):
            // Numerics sort before strings in cross-type comparisons
            false
        case (.double, .string), (.integer, .string):
            true
        }
    }
}
