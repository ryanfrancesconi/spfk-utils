
#if canImport(AppKit) && !targetEnvironment(macCatalyst)

    import AppKit
    import Foundation
    import SPFKTesting
    @testable import SPFKUtils
    import Testing

    class ColorTests: TestCaseModel {
        @Test func hexColorInit() async throws {
            let hexColor = HexColor(hexString: "FF0000")

            #expect(hexColor.cgColor == CGColor(red: 1, green: 0, blue: 0, alpha: 1))
            #expect(hexColor.nsColor == NSColor(calibratedRed: 1, green: 0, blue: 0, alpha: 1))
        }

        @Test func hexColorCodable() async throws {
            let hexColor = HexColor(hexString: "FF0000")

            let encoder = PropertyListEncoder()
            let data = try encoder.encode(hexColor)

            let unencoded = try PropertyListDecoder().decode(HexColor.self, from: data)

            #expect(hexColor == unencoded)
        }
    }

#endif
