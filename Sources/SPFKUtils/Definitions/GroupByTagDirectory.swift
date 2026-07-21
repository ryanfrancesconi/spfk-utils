// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKBase

/// Resolves an output directory by appending subdirectories derived from tag values.
///
/// Given an ordered list of string keys, each key is looked up in a `[String: String]`
/// tags dictionary. Non-empty values are split on `"/"` to support nested folder paths
/// (e.g. `"Music/Classical"` → `Music/Classical/`), sanitized, and appended in order
/// to the base directory.
public struct GroupByTagDirectory {
    public let keys: [String]

    /// Creates a resolver with an ordered list of tag keys.
    /// An empty keys list always returns `base` unchanged.
    public init(_ keys: [String] = []) {
        self.keys = keys
    }

    /// Resolves the output directory, appending subdirectories from each key's tag value.
    ///
    /// Keys with missing or blank values are skipped. Each value is split on `"/"` to
    /// support nested folder paths.
    public func resolve(base: URL, tags: [String: String]) -> URL {
        var result = base
        for key in keys {
            guard
                let value = tags[key],
                !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { continue }

            let components = value
                .components(separatedBy: "/")
                .map(\.sanitizedPathComponent)
                .filter { !$0.isEmpty }

            result = components.reduce(result) {
                $0.appending(component: $1, directoryHint: .isDirectory)
            }
        }
        return result
    }
}

// MARK: - Path Sanitization

extension String {
    /// Trims whitespace, normalizes to title case, and replaces `:` (which macOS Finder treats as `/`) with `-`.
    public var sanitizedPathComponent: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .displayTitleCased
            .replacingOccurrences(of: ":", with: "-")
    }
}
