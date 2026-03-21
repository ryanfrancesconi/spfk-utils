// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import CoreGraphics
import Foundation
import SPFKBase
import SPFKTesting
import Testing

@testable import SPFKUtils

class HexColorTests: TestCaseModel {
    // MARK: - String init

    @Test func initNoAlpha() throws {
        let hexColor = try #require(HexColor(string: "FF0000"))

        #expect(hexColor.red == 1)
        #expect(hexColor.green == 0)
        #expect(hexColor.blue == 0)
        #expect(hexColor.alpha == 1)
        #expect(hexColor.stringValue == "FF0000FF")
    }

    @Test func initWithAlpha() throws {
        let hexColor = try #require(HexColor(string: "FF000080"))

        #expect(hexColor.red == 1)
        #expect(hexColor.green == 0)
        #expect(hexColor.blue == 0)
        #expect(hexColor.alpha == 128.0 / 255.0)
        #expect(hexColor.stringValue == "FF000080")
    }

    @Test func initWithHashPrefix() throws {
        let hexColor = try #require(HexColor(string: "#FF0000"))

        #expect(hexColor.red == 1)
        #expect(hexColor.green == 0)
        #expect(hexColor.blue == 0)
        #expect(hexColor.alpha == 1)
        #expect(hexColor.stringValue == "FF0000FF")
    }

    @Test func initInvalidStringReturnsNil() {
        #expect(HexColor(string: "ZZZ") == nil)
        #expect(HexColor(string: "") == nil)
        #expect(HexColor(string: "FFF") == nil)
    }

    // MARK: - Component init

    @Test func componentInit() {
        let hexColor = HexColor(red: 1, green: 0, blue: 0, alpha: 0.5)

        #expect(hexColor.red == 1)
        #expect(hexColor.green == 0)
        #expect(hexColor.blue == 0)
        #expect(hexColor.alpha == 0.5)
        #expect(hexColor.stringValue == "FF000080")
    }

    @Test func componentInitClampsValues() {
        let hexColor = HexColor(red: 2.0, green: -1.0, blue: 0.5, alpha: 1.5)

        #expect(hexColor.red == 1)
        #expect(hexColor.green == 0)
        #expect(hexColor.blue == 0.5)
        #expect(hexColor.alpha == 1)
    }

    @Test func componentInitDefaultAlpha() {
        let hexColor = HexColor(red: 1, green: 0, blue: 0)
        #expect(hexColor.alpha == 1)
        #expect(hexColor.stringValue == "FF0000FF")
    }

    // MARK: - cgColor

    @Test func cgColorNonOptional() throws {
        let hexColor = try #require(HexColor(string: "FF0000"))
        let cg: CGColor = hexColor.cgColor // non-optional assignment
        #expect(cg.components == [1, 0, 0, 1])
    }

    @Test func cgColorWithAlpha() throws {
        let hexColor = try #require(HexColor(string: "FF000080"))
        let components = try #require(hexColor.cgColor.components)
        #expect(components[0] == 1)
        #expect(components[1] == 0)
        #expect(components[2] == 0)
        #expect(components[3] == 128.0 / 255.0)
    }

    @Test func cgColorIsSRGB() throws {
        let hexColor = try #require(HexColor(string: "336699FF"))
        #expect(hexColor.cgColor.colorSpace?.name == CGColorSpace.sRGB as CFString)
    }

    // MARK: - rgbStringValue

    @Test func rgbStringValueStripsAlpha() throws {
        let hexColor = try #require(HexColor(string: "FF000080"))
        #expect(hexColor.rgbStringValue == "FF0000")
    }

    @Test func rgbStringValueForFullAlpha() throws {
        let hexColor = try #require(HexColor(string: "00FF00"))
        #expect(hexColor.rgbStringValue == "00FF00")
        #expect(hexColor.stringValue == "00FF00FF")
    }

    // MARK: - Equality and Hashing

    @Test func equalityAcrossFormats() throws {
        let sixChar = try #require(HexColor(string: "FF0000"))
        let eightChar = try #require(HexColor(string: "FF0000FF"))

        #expect(sixChar == eightChar)
    }

    @Test func hashConsistency() throws {
        let a = try #require(HexColor(string: "FF0000"))
        let b = try #require(HexColor(string: "FF0000FF"))

        #expect(a.hashValue == b.hashValue)
    }

    @Test func inequalityDifferentAlpha() throws {
        let opaque = try #require(HexColor(string: "FF0000FF"))
        let transparent = try #require(HexColor(string: "FF000080"))

        #expect(opaque != transparent)
    }

    // MARK: - Codable

    @Test func codableRoundTrip() throws {
        let hexColor = try #require(HexColor(string: "FF000080"))

        let data = try PropertyListEncoder().encode(hexColor)
        let decoded = try PropertyListDecoder().decode(HexColor.self, from: data)

        #expect(hexColor == decoded)
        #expect(decoded.stringValue == "FF000080")
    }

    @Test func codableNormalizes6CharInput() throws {
        let original = try #require(HexColor(string: "FF0000"))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HexColor.self, from: data)

        #expect(decoded.stringValue == "FF0000FF")
        #expect(decoded == original)
    }

    @Test func codableMissingKeyThrows() {
        let json = "{}".data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(HexColor.self, from: json)
        }
    }

    @Test func codableInvalidHexThrows() {
        let json = "{\"stringValue\":\"ZZZZZZ\"}".data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(HexColor.self, from: json)
        }
    }
}

// MARK: - NSColor bridge (macOS only)

#if os(macOS)
    import AppKit

    extension HexColorTests {
        @Test func nsColorInit() {
            let alphaRed = HexColor(nsColor: NSColor.red.withAlphaComponent(0.5))

            #expect(alphaRed?.stringValue == "FF000080")
        }

        @Test func nsColorRoundTrip() throws {
            let original = try #require(HexColor(string: "336699FF"))
            let nsColor = try #require(original.nsColor)
            let roundTripped = HexColor(nsColor: nsColor)
            #expect(roundTripped == original)
        }

        @Test func nsColorFromCGColor() throws {
            let hexColor = try #require(HexColor(string: "FF000080"))
            let nsColor = try #require(hexColor.nsColor)
            let srgb = try #require(nsColor.usingColorSpace(.sRGB))
            #expect(srgb.redComponent == 1)
            #expect(srgb.greenComponent == 0)
            #expect(srgb.blueComponent == 0)
            #expect(srgb.alphaComponent == 128.0 / 255.0)
        }
    }
#endif
