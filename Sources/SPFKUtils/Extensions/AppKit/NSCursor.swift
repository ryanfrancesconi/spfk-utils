// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import AppKit

    extension NSCursor {
        /// Returns the cursor for dragging a row divider up or down.
        /// Uses the modern `rowResize` API on macOS 15+; falls back to `resizeUpDown` on earlier systems.
        public static var rowResizeCursor: NSCursor {
            if #available(macOS 15.0, *) { return .rowResize }
            return .resizeUpDown
        }

        /// Returns the cursor for dragging a column divider left or right.
        /// Uses the modern `columnResize` API on macOS 15+; falls back to `resizeLeftRight` on earlier systems.
        public static var columnResizeCursor: NSCursor {
            if #available(macOS 15.0, *) { return .columnResize }
            return .resizeLeftRight
        }
    }
#endif
