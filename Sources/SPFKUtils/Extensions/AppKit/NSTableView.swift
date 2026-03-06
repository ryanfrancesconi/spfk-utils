// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit

    extension NSTableView {
        public func selectNextRow(byExtendingSelection: Bool = false) throws {
            var nextRow = min(numberOfRows - 1, selectedRow + 1)

            if hiddenRowIndexes.isNotEmpty, hiddenRowIndexes.contains(nextRow) {
                for i in nextRow ..< numberOfRows {
                    if !hiddenRowIndexes.contains(i) {
                        nextRow = i
                        break
                    }
                }
            }

            guard nextRow > selectedRow else {
                throw NSError(description: "This is the last row")
            }

            let selectRow = IndexSet(integer: nextRow)
            selectRowIndexes(selectRow, byExtendingSelection: byExtendingSelection)
            scrollSelectedRowToVisible()
        }

        public func selectPreviousRow(byExtendingSelection: Bool = false) throws {
            guard selectedRow - 1 >= 0 else {
                throw NSError(description: "This is the first row")
            }

            var nextRow = max(0, selectedRow - 1)

            if hiddenRowIndexes.isNotEmpty, hiddenRowIndexes.contains(nextRow) {
                var i = nextRow
                while i >= 0 {
                    if !hiddenRowIndexes.contains(i) {
                        nextRow = i
                        break
                    }
                    i -= 1
                }
            }

            let selectRow = IndexSet(integer: nextRow)
            selectRowIndexes(selectRow, byExtendingSelection: byExtendingSelection)
            scrollSelectedRowToVisible()
        }

        public func scrollSelectedRowToVisible() {
            scrollRowToVisible(selectedRow)
        }

        /// an `IndexSet` containing the indices of all columns in the table view
        public var allColumnIndexes: IndexSet {
            var indexSet = IndexSet()

            for i in 0 ..< tableColumns.count {
                indexSet.insert(i)
            }

            return indexSet
        }
    }
#endif
