// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import CoreGraphics
import Foundation

/// A lightweight, Codable color type that serializes as an 8-character RGBA hex string (e.g. `"FF000080"`).
///
/// `HexColor` is designed for persistent storage via `Codable` and SwiftData. It stores normalized
/// RGBA components and bridges to `CGColor` directly, with optional `NSColor` conversion on macOS.
/// Equality and hashing are based solely on `stringValue`, ensuring consistent behavior across
/// construction paths.
public struct HexColor: Hashable, Sendable, Equatable, Comparable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.stringValue == rhs.stringValue
    }

    /// Sorts by HSB hue (rainbow order). Achromatic colors (saturation < 0.05)
    /// are placed at the end, sorted by brightness.
    public static func < (lhs: Self, rhs: Self) -> Bool {
        let (lh, ls, lb) = lhs.hsb
        let (rh, rs, rb) = rhs.hsb

        let lChromatic = ls >= 0.05
        let rChromatic = rs >= 0.05

        // Chromatic colors before achromatic
        if lChromatic != rChromatic { return lChromatic }

        if lChromatic {
            // Both chromatic: sort by hue, then saturation, then brightness
            if lh != rh { return lh < rh }
            if ls != rs { return ls < rs }
            return lb < rb
        } else {
            // Both achromatic: sort by brightness
            return lb < rb
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(stringValue)
    }

    /// Always 8-character RGBA hex string (e.g. "FF0000FF").
    public private(set) var stringValue: String = "FFFFFFFF"

    public private(set) var red: CGFloat = 1
    public private(set) var green: CGFloat = 1
    public private(set) var blue: CGFloat = 1
    public private(set) var alpha: CGFloat = 1

    /// Returns the 6-character RGB hex string without alpha (e.g. "FF0000").
    public var rgbStringValue: String {
        String(stringValue.prefix(6))
    }

    /// Computed from stored RGBA components. Not a stored property because SwiftData
    /// introspects composite types at runtime and `CGColor` is not a supported type.
    public var cgColor: CGColor {
        Self.makeCGColor(red, green, blue, alpha)
    }

    /// Returns (hue, saturation, brightness) computed from RGB components.
    /// Hue is in the range 0...360, saturation and brightness are 0...1.
    public var hsb: (hue: CGFloat, saturation: CGFloat, brightness: CGFloat) {
        let maxC = max(red, green, blue)
        let minC = min(red, green, blue)
        let delta = maxC - minC

        let brightness = maxC

        guard delta > 0.0001 else {
            return (hue: 0, saturation: 0, brightness: brightness)
        }

        let saturation = maxC > 0 ? delta / maxC : 0

        var hue: CGFloat
        if red == maxC {
            hue = (green - blue) / delta
        } else if green == maxC {
            hue = 2 + (blue - red) / delta
        } else {
            hue = 4 + (red - green) / delta
        }

        hue *= 60
        if hue < 0 { hue += 360 }

        return (hue: hue, saturation: saturation, brightness: brightness)
    }

    // MARK: - Initializers

    /// Create from a hex string. Accepts 6-char RGB or 8-char RGBA, with or without `#` prefix.
    /// Returns `nil` if the string is not a valid hex color.
    public init?(string: String) {
        stringValue = string.trimmed
        guard parse() else { return nil }
    }

    /// Create from RGBA component values (0-1 range, clamped).
    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1) {
        self.red = min(max(red, 0), 1)
        self.green = min(max(green, 0), 1)
        self.blue = min(max(blue, 0), 1)
        self.alpha = min(max(alpha, 0), 1)
        stringValue = Self.formatRGBA(self.red, self.green, self.blue, self.alpha)
    }

    /// Create from HSB components. Hue is 0...360, saturation and brightness are 0...1.
    public init(hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat = 1) {
        let h = min(max(hue, 0), 360)
        let s = min(max(saturation, 0), 1)
        let b = min(max(brightness, 0), 1)
        let a = min(max(alpha, 0), 1)

        let c = b * s
        let x = c * (1 - abs((h / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m = b - c

        let r1, g1, b1: CGFloat
        switch h {
        case 0 ..< 60: (r1, g1, b1) = (c, x, 0)
        case 60 ..< 120: (r1, g1, b1) = (x, c, 0)
        case 120 ..< 180: (r1, g1, b1) = (0, c, x)
        case 180 ..< 240: (r1, g1, b1) = (0, x, c)
        case 240 ..< 300: (r1, g1, b1) = (x, 0, c)
        default: (r1, g1, b1) = (c, 0, x)
        }

        self.init(red: r1 + m, green: g1 + m, blue: b1 + m, alpha: a)
    }

    // MARK: - Private

    private static let sRGBColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

    private static func makeCGColor(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat) -> CGColor {
        CGColor(colorSpace: sRGBColorSpace, components: [r, g, b, a])!
    }

    private static func formatRGBA(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat) -> String {
        String(
            format: "%02lX%02lX%02lX%02lX",
            lroundf(Float(r) * 255),
            lroundf(Float(g) * 255),
            lroundf(Float(b) * 255),
            lroundf(Float(a) * 255)
        )
    }

    /// Returns `true` if parsing succeeded.
    @discardableResult
    private mutating func parse() -> Bool {
        var string = stringValue
        if string.hasPrefix("#") { string = String(string.dropFirst()) }

        guard let hexNumber = UInt64(string, radix: 16) else {
            return false
        }

        // 8-char RGBA: FF000080
        if string.count == 8 {
            red = CGFloat((hexNumber & 0xFF00_0000) >> 24) / 255.0
            green = CGFloat((hexNumber & 0x00FF_0000) >> 16) / 255.0
            blue = CGFloat((hexNumber & 0x0000_FF00) >> 8) / 255.0
            alpha = CGFloat(hexNumber & 0x0000_00FF) / 255.0

            // 6-char RGB: FF0000
        } else if string.count == 6 {
            red = CGFloat((hexNumber & 0xFF0000) >> 16) / 255.0
            green = CGFloat((hexNumber & 0x00FF00) >> 8) / 255.0
            blue = CGFloat((hexNumber & 0x0000FF) >> 0) / 255.0

        } else {
            return false
        }

        // Always normalize to 8-character RGBA format
        stringValue = Self.formatRGBA(red, green, blue, alpha)
        return true
    }
}

// MARK: - Codable

extension HexColor: Codable {
    enum CodingKeys: String, CodingKey {
        case stringValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stringValue = try container.decode(String.self, forKey: .stringValue)
        guard parse() else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: container.codingPath, debugDescription: "Invalid hex color string: \(stringValue)")
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(stringValue, forKey: .stringValue)
    }
}
