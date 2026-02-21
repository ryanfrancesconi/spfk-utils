// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit

    extension HexColor {
        public var nsColor: NSColor? {
            NSColor.from(hexColor: self)
        }

        public init?(nsColor: NSColor) {
            guard let string = nsColor.toHex() else {
                return nil
            }

            stringValue = string.trimmed
            parse()
        }
    }
#endif
