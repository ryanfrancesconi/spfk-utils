// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import CoreGraphics
import Foundation

/// A lightweight, Codable color type that serializes as an 8-character RGBA hex string (e.g. `"FF000080"`).
///
/// `HexColor` is designed for persistent storage via `Codable` and SwiftData. It stores normalized
/// RGBA components and bridges to `CGColor` directly, with optional `NSColor` conversion on macOS.
/// Equality and hashing are based solely on `stringValue`, ensuring consistent behavior across
/// construction paths.
public struct HexColor: Hashable, Sendable, Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.stringValue == rhs.stringValue
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

            alpha = alpha.rounded(decimalPlaces: 2)

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

    /// SwiftData may create empty containers for nil optional composite types.
    /// Throw when the key is missing so callers using try? get nil.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let value = try container.decodeIfPresent(String.self, forKey: .stringValue) else {
            throw DecodingError.valueNotFound(
                HexColor.self,
                .init(codingPath: container.codingPath, debugDescription: "Empty container for optional HexColor")
            )
        }

        stringValue = value

        guard parse() else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: container.codingPath, debugDescription: "Invalid hex color string: \(value)")
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(stringValue, forKey: .stringValue)
    }
}
