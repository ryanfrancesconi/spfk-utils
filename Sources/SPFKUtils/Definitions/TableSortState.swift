// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// Persisted sort order for a table view: which column, and which direction.
///
/// `identifier` is the stable column identifier (`NSTableColumn.identifier.rawValue`), the same
/// string `TableColumnState.identifier` holds and the same one `NSSortDescriptor.key` carries —
/// never the localized header title, which would not survive a language change.
public struct TableSortState: Sendable, Hashable, Equatable, Codable {
    public var identifier: String
    public var ascending: Bool

    public init(identifier: String, ascending: Bool) {
        self.identifier = identifier
        self.ascending = ascending
    }
}
