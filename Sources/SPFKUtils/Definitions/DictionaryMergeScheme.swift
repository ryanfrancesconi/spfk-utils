// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// When used with merging dictionaries, can specify how the
/// values are combined.
///
///     @inlinable public func merging(_ other: [Key : Value], uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> [Key : Value]
public enum DictionaryMergeScheme: Sendable, Hashable {
    case preserve
    case replace
    case combine
}
