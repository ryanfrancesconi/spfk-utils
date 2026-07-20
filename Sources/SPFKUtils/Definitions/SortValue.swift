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
        case (.string(let a), .string(let b)):
            return a.localizedStandardCompare(b) == .orderedAscending
        case (.double(let a), .double(let b)):
            return a < b
        case (.integer(let a), .integer(let b)):
            return a < b
        case (.integer(let a), .double(let b)):
            return Double(a) < b
        case (.double(let a), .integer(let b)):
            return a < Double(b)
        case (.string, .double), (.string, .integer):
            // Numerics sort before strings in cross-type comparisons
            return false
        case (.double, .string), (.integer, .string):
            return true
        }
    }
}
