// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// A token the name editor can insert, without the element type it reads.
public struct NameTokenMenuEntry: Sendable, Hashable {
    /// The token as a template holds it: `{field:Camera}`.
    public let source: String
    public let title: String
    public let placement: SpreadsheetFieldMenuPlacement?

    public init(source: String, title: String, placement: SpreadsheetFieldMenuPlacement?) {
        self.source = source
        self.title = title
        self.placement = placement
    }
}
