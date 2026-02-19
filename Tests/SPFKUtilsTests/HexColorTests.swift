// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
    import Foundation
    import Numerics
    import SPFKTesting
    import Testing

    @testable import SPFKUtils

    class HexColorTests: TestCaseModel {
        @Test func nsColorInit() async throws {
            let alphaRed = HexColor(nsColor: NSColor.red.withAlphaComponent(0.5))
            Log.debug(alphaRed?.stringValue)

            #expect(alphaRed?.stringValue == "FF000080")
        }

        @Test func initAlpha() async throws {
            let hexColor = HexColor(string: "FF000080")

            #expect(hexColor.red == 1)
            #expect(hexColor.green == 0)
            #expect(hexColor.blue == 0)
            #expect(hexColor.alpha == 0.5)

            #expect(hexColor.cgColor == CGColor(red: 1, green: 0, blue: 0, alpha: 0.5))
            #expect(hexColor.nsColor == NSColor(calibratedRed: 1, green: 0, blue: 0, alpha: 0.5))
        }

        @Test func initNoAlpha() async throws {
            let hexColor = HexColor(string: "FF0000")

            #expect(hexColor.red == 1)
            #expect(hexColor.green == 0)
            #expect(hexColor.blue == 0)
            #expect(hexColor.alpha == 1)
        }

        @Test func hexColorCodable() async throws {
            let hexColor = HexColor(string: "FF000080")

            let encoder = PropertyListEncoder()
            let data = try encoder.encode(hexColor)

            let decodedValue = try PropertyListDecoder().decode(HexColor.self, from: data)

            #expect(hexColor == decodedValue)
        }
    }

#endif
