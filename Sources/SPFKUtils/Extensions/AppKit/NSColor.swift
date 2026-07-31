// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import AppKit
    import SPFKBase

    extension NSColor {
        public static var random: NSColor {
            let r = CGFloat.random(in: 0.05 ... 0.95)
            let g = CGFloat.random(in: 0.05 ... 0.95)
            let b = CGFloat.random(in: 0.05 ... 0.95)

            return NSColor(calibratedRed: r, green: g, blue: b, alpha: 1.0)
        }

        public static var randomPastel: NSColor {
            NSColor(calibratedRed: CGFloat.random(in: 0.05 ... 0.95),
                    green: 0.3,
                    blue: 0.2,
                    alpha: 1.0)
        }

        public static var randomGray: NSColor {
            let value = CGFloat.random(in: CGFloat.unitIntervalRange)

            return NSColor(calibratedRed: value,
                           green: value,
                           blue: value,
                           alpha: 1.0)
        }
    }

    extension NSColor {
        public func darker(by amount: CGFloat = 0.2) -> NSColor {
            shadow(withLevel: amount) ?? self
        }

        public func lighter(by amount: CGFloat = 0.2) -> NSColor {
            highlight(withLevel: amount) ?? self
        }

        /// Keeps the hue and alpha, replacing saturation and brightness.
        /// Returns `self` unchanged if the color can't be converted to an HSB-capable space.
        public func with(saturation: CGFloat, brightness: CGFloat) -> NSColor {
            guard let converted = usingColorSpace(.deviceRGB) else { return self }

            return NSColor(
                hue: converted.hueComponent,
                saturation: saturation,
                brightness: brightness,
                alpha: converted.alphaComponent
            )
        }
    }

    extension NSColor {
        public var hexColor: HexColor? {
            guard let string = toHex() else { return nil }
            return HexColor(string: string)
        }

        public static func from(hexColor: HexColor) -> NSColor? {
            NSColor(cgColor: hexColor.cgColor)
        }

        public func toHex(alpha: Bool = true) -> String? {
            cgColor.toHex(alpha: alpha)
        }
    }

    extension CGColor {
        public var nsColor: NSColor? {
            NSColor(cgColor: self)
        }
    }

#endif
