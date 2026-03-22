// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// Broad color region names derived from HSB values. Used for search indexing
/// so users can find files by typing color names like "red" or "blue".
public enum ColorName: String, CaseIterable, Sendable {
    case red
    case orange
    case yellow
    case green
    case cyan
    case blue
    case purple
    case pink
    case brown
    case white
    case gray
    case black

    /// Initialize from HSB components. Hue is 0...360, saturation and brightness are 0...1.
    public init(hue: CGFloat, saturation: CGFloat, brightness: CGFloat) {
        // Very dark colors
        if brightness < 0.15 {
            self = .black
            return
        }

        // Very light, desaturated colors
        if saturation < 0.1 && brightness > 0.85 {
            self = .white
            return
        }

        // Desaturated colors
        if saturation < 0.15 {
            self = brightness < 0.5 ? .black : .gray
            return
        }

        // Brown: low-to-medium brightness in the orange-yellow hue range
        if saturation > 0.2 && brightness < 0.55 && (hue < 45 || hue >= 345) {
            self = .brown
            return
        }

        // Chromatic: bucket by hue
        switch hue {
        case 0 ..< 15: self = .red
        case 15 ..< 45: self = .orange
        case 45 ..< 70: self = .yellow
        case 70 ..< 160: self = .green
        case 160 ..< 195: self = .cyan
        case 195 ..< 255: self = .blue
        case 255 ..< 290: self = .purple
        case 290 ..< 345: self = .pink
        default: self = .red // 345-360 wraps back to red
        }
    }
}

extension HexColor {
    /// A human-readable color region name derived from this color's HSB values.
    /// Suitable for search indexing — e.g. "red", "blue", "gray".
    public var colorName: ColorName {
        let (h, s, b) = hsb
        return ColorName(hue: h, saturation: s, brightness: b)
    }
}
