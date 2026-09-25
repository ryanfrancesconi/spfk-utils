// Copyright Ryan Francesconi. All Rights Reserved.

#if os(macOS)

    import Foundation
    import SPFKBase
    import SPFKFileSystem
    import Testing

    @testable import SPFKUtils

    /// A hex color text tag survives a `URLProperties` Codable round-trip.
    @Suite
    final class URLPropertiesHexColorTagTests {
        @Test func encodeDecodeURLPropertiesWithHexColorTag() throws {
            var urlProps = URLProperties(url: URL(fileURLWithPath: "/tmp/test.wav"))
            urlProps.finderTags.updateCustom(hexColor: HexColor(string: "FFFF00FF"))

            let data = try JSONEncoder().encode(urlProps)
            let decoded = try JSONDecoder().decode(URLProperties.self, from: data)

            #expect(decoded.finderTags.hexColorTag?.stringValue == "FFFF00FF")
        }

        @Test func encodeDecodeURLPropertiesWithMixedTags() throws {
            var urlProps = URLProperties(url: URL(fileURLWithPath: "/tmp/test.wav"))
            urlProps.finderTags = FinderTagGroup(tags: [
                FinderTagDescription(tagColor: .red),
                FinderTagDescription(tagColor: .green),
            ])
            urlProps.finderTags.updateCustom(hexColor: HexColor(string: "FF2160FF"))

            let data = try JSONEncoder().encode(urlProps)
            let decoded = try JSONDecoder().decode(URLProperties.self, from: data)

            #expect(decoded.finderTags.tags.count == 3)
            #expect(decoded.finderTags.hexColorTag?.stringValue == "FF2160FF")
        }
    }

#endif
