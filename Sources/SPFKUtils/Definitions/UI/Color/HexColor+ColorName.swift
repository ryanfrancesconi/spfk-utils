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
        if saturation < 0.1, brightness > 0.85 {
            self = .white
            return
        }

        // Desaturated colors
        if saturation < 0.15 {
            self = brightness < 0.5 ? .black : .gray
            return
        }

        // Brown: low-to-medium brightness in the orange-yellow hue range
        if saturation > 0.2, brightness < 0.55, hue < 45 || hue >= 345 {
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
        case 195 ..< 245: self = .blue
        case 245 ..< 290: self = .purple
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

    /// A display-friendly color name with lightness/saturation qualifiers.
    ///
    /// Returns strings like "Dark Red", "Light Blue", "Pale Green", or just "Red"
    /// for mid-range colors. Achromatic colors (black, white, gray) are returned
    /// without qualifiers since their names already imply lightness.
    public var colorDisplayName: String {
        let (h, s, b) = hsb

        // Achromatic — no qualifier needed, the name itself implies lightness
        if b < 0.15 { return "Black" }
        if s < 0.1, b > 0.85 { return "White" }
        if s < 0.15 { return b < 0.5 ? "Black" : "Gray" }

        // For chromatic colors, derive the hue name directly so that
        // dark warm colors (which colorName classifies as "brown") get
        // proper qualifiers like "Dark Red" instead of just "Brown".
        //
        // The blue/purple boundary is saturation-dependent: at hue ~240,
        // desaturated colors (lavender, periwinkle) read as purple while
        // saturated colors read as blue.
        let bluePurpleBoundary: CGFloat = s < 0.5 ? 235 : 245

        let hueName: String =
            switch h {
            case 0 ..< 15: "Red"
            case 15 ..< 45: "Orange"
            case 45 ..< 70: "Yellow"
            case 70 ..< 160: "Green"
            case 160 ..< 195: "Cyan"
            case 195 ..< bluePurpleBoundary: "Blue"
            case bluePurpleBoundary ..< 290: "Purple"
            case 290 ..< 345: "Pink"
            default: "Red" // 345-360 wraps back to red
            }

        if b < 0.6 {
            return "Dark \(hueName)"
        } else if s < 0.35, b > 0.7 {
            return "Pale \(hueName)"
        } else if b > 0.8, s > 0.15, s < 0.65 {
            return "Light \(hueName)"
        }

        return hueName
    }
}
