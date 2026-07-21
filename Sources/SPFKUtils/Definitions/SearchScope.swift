// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// Whether a search covers everything in scope, or only the current selection.
public enum SearchScope: Int, Sendable, CaseIterable, Hashable, Codable {
    case all
    case selected

    public var displayName: String {
        switch self {
        case .all:
            localized("All")
        case .selected:
            localized("Selected")
        }
    }

    public var stringValue: String {
        switch self {
        case .all:
            localized("Search All")
        case .selected:
            localized("Search Selected")
        }
    }
}
