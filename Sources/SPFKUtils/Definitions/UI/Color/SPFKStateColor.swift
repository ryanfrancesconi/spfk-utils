// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)

    import AppKit

    public struct SPFKStateColor {
        public var selected: SPFKColor = .controlAccentColor
        public var unselected: SPFKColor = .controlBackgroundColor
        public var disabled: SPFKColor = .controlAlphaBackgroundColor

        public init() {}

        public init(selected: SPFKColor, unselected: SPFKColor, disabled: SPFKColor? = nil) {
            self.selected = selected
            self.unselected = unselected
            if let disabled {
                self.disabled = disabled
            }
        }

        public subscript(_ state: NSControl.StateValue) -> SPFKColor {
            state == .on ? selected : unselected
        }
    }

    // MARK: -

    public struct StateColor {
        public var selected: NSColor = SPFKColor.controlAccentColor.nsColor
        public var unselected: NSColor = SPFKColor.controlBackgroundColor.nsColor
        public var disabled: NSColor = SPFKColor.controlAlphaBackgroundColor.nsColor

        public init() {}

        public init(selected: NSColor, unselected: NSColor, disabled: NSColor? = nil) {
            self.selected = selected
            self.unselected = unselected
            if let disabled {
                self.disabled = disabled
            }
        }

        public subscript(_ state: NSControl.StateValue) -> NSColor {
            state == .on ? selected : unselected
        }
    }

#endif
