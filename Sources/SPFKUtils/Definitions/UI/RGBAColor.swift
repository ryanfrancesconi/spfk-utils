// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

public struct RGBAColor: Hashable, Sendable, Equatable {
    public var r: CGFloat = 0.0
    public var g: CGFloat = 0.0
    public var b: CGFloat = 0.0
    public var a: CGFloat = 1.0

    public init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    public init(hexString: String) throws {
        var hexString = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.replacingOccurrences(of: "#", with: "")

        let length = hexString.count

        var rgb: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgb)

        switch length {
        case 6:
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0

        case 8:
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0

        default:
            throw NSError(description: "Invalid string passed to constructor \(hexString)")
        }
    }
}
