// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

extension NSOutlineView {
    public func collapseSelectedRows(collapseChildren: Bool = false) {
        for row in selectedRowIndexes.sorted().reversed() {
            collapseItem(item(atRow: row),
                         collapseChildren: collapseChildren)
        }
    }

    public func expandSelectedRows(expandChildren: Bool = false) {
        for row in selectedRowIndexes.sorted().reversed() {
            expandItem(item(atRow: row),
                       expandChildren: expandChildren)
        }
    }
}
#endif
