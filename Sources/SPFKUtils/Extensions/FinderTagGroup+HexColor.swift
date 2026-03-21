// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)

    import Foundation
    import SPFKFileSystem

    extension FinderTagGroup {
        /// Returns the first hex color text tag (e.g. "FF6B2CFF"), or nil.
        ///
        /// Scans text-only tags (`.none` color) looking for one whose label
        /// is a valid 8-character RGBA hex string.
        public var hexColorTag: HexColor? {
            for tag in tags where tag.tagColor == .none {
                if let hex = HexColor(string: tag.label) { return hex }
            }
            return nil
        }

        /// Set or remove the custom hex color text tag.
        ///
        /// Removes any existing hex-color text tags first, then appends
        /// a new one if `hexColor` is non-nil.
        public mutating func setHexColorTag(_ hexColor: HexColor?) {
            // Remove existing hex color text tags
            tags.removeAll { $0.tagColor == .none && HexColor(string: $0.label) != nil }

            // Add new one if provided
            if let hexColor {
                tags.append(FinderTagDescription(label: hexColor.stringValue))
            }
        }
    }

#endif
