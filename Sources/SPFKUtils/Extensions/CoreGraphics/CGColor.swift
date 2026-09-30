// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import CoreGraphics
import Foundation

extension CGColor {
    /// The color's sRGB value as hex digits, `RRGGBB` or `RRGGBBAA`. Nil when it cannot be
    /// converted to sRGB.
    public func toHex(alpha: Bool = false) -> String? {
        guard let srgb = CGColorSpace(name: CGColorSpace.sRGB),
              let converted = converted(to: srgb, intent: .defaultIntent, options: nil),
              let components = converted.components,
              components.count >= 3
        else {
            return nil
        }

        func byte(_ value: CGFloat) -> Int {
            lround(Double(min(max(value, 0), 1)) * 255)
        }

        let r = byte(components[0])
        let g = byte(components[1])
        let b = byte(components[2])
        let a = components.count >= 4 ? byte(components[3]) : 255

        if alpha {
            return String(format: "%02lX%02lX%02lX%02lX", r, g, b, a)
        } else {
            return String(format: "%02lX%02lX%02lX", r, g, b)
        }
    }
}
