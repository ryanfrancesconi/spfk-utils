// Copyright Ryan Francesconi. All Rights Reserved.

#if os(macOS)
    import AppKit
    import CoreGraphics
    import Foundation
    import Testing

    @testable import SPFKUtils

    struct CGColorHexConversionTests {
        /// The same color's hex digits computed through AppKit's own sRGB conversion.
        private func expectedHex(_ color: CGColor) throws -> String {
            let srgb = try #require(NSColor(cgColor: color)?.usingColorSpace(.sRGB))
            let bytes = [srgb.redComponent, srgb.greenComponent, srgb.blueComponent, srgb.alphaComponent]
                .map { lround(Double(min(max($0, 0), 1)) * 255) }
            return bytes.map { String(format: "%02lX", $0) }.joined()
        }

        @Test func aGrayColorProducesAHexValue() throws {
            let gray = CGColor(gray: 0.5, alpha: 1)
            let hex = try #require(gray.toHex(alpha: true))
            #expect(hex == (try expectedHex(gray)))
        }

        @Test func aCMYKColorIsConvertedRatherThanReadAsRGBA() throws {
            let cyan = CGColor(genericCMYKCyan: 1, magenta: 0, yellow: 0, black: 0, alpha: 1)
            let hex = try #require(cyan.toHex(alpha: true))
            #expect(hex.hasSuffix("FF"))
            #expect(hex == (try expectedHex(cyan)))
        }

        @Test func aDisplayP3ColorIsConvertedToSRGB() throws {
            let space = try #require(CGColorSpace(name: CGColorSpace.displayP3))
            let p3 = try #require(CGColor(colorSpace: space, components: [0.6, 0.4, 0.2, 1]))
            let hex = try #require(p3.toHex(alpha: true))
            #expect(hex == (try expectedHex(p3)))
        }
    }
#endif
