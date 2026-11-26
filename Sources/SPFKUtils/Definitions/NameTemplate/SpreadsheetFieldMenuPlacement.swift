// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// Where a field sits in a field menu, as the product's own column menus place it.
public struct SpreadsheetFieldMenuPlacement: Hashable, Sendable {
    /// Blocks are listed in ascending order with a separator between them.
    public let block: Int
    /// The submenu titles leading to the field; empty puts it at the top of its block.
    public let path: [String]
    /// Sorts the fields within a block. Submenus appear in the order of their first field.
    public let order: Int

    public init(block: Int, path: [String], order: Int) {
        self.block = block
        self.path = path
        self.order = order
    }
}
