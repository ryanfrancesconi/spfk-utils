// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)

    import AppKit

    public struct SelectedColor {
        public var selected: NSColor = .controlAccentColor
        public var unselected: NSColor = .controlColor

        public init() {}

        public init(selected: NSColor, unselected: NSColor) {
            self.selected = selected
            self.unselected = unselected
        }
        
        public func color(state: Bool) -> NSColor {
            state ? selected : unselected
        }
    }

#endif
