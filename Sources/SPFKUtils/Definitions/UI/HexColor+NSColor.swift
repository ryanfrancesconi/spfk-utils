// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import AppKit

    extension HexColor {
        public var nsColor: NSColor? {
            NSColor(cgColor: cgColor)
        }

        public init?(nsColor: NSColor) {
            guard let rgb = nsColor.usingColorSpace(.sRGB) else { return nil }
            self.init(
                red: rgb.redComponent,
                green: rgb.greenComponent,
                blue: rgb.blueComponent,
                alpha: rgb.alphaComponent
            )
        }
    }
#endif
