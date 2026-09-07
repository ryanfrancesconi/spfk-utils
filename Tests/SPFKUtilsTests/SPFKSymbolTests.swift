// Copyright Ryan Francesconi. All Rights Reserved.

#if os(macOS)

    import AppKit
    import Foundation
    import SPFKBase
    import SPFKUtils
    import Testing

    /// Whether every symbol name actually names a symbol.
    ///
    /// `nsImage` returns `nil` for a name AppKit cannot resolve, and nothing above it reports that
    /// — a menu item just renders with no icon. `linesDecrease` carried three `U+200B` zero-width
    /// spaces inside its raw value and had been unresolvable for as long as it existed; the name
    /// reads correctly at every glance, which is exactly why it survived.
    ///
    /// Serialized because the legacy checks set `OSVersion.simulatedUnavailableFrom`.
    @Suite(.serialized)
    struct SPFKSymbolTests {
        @Test func everySymbolResolves() {
            let unresolved = SPFKSymbol.allCases
                .filter { $0.nsImage == nil || $0.tinted(color: .white) == nil }
                .map(\.systemSymbolName)

            #expect(unresolved.isEmpty, "unresolvable symbol names: \(unresolved)")
        }

        /// A fallback is only reachable on an OS older than this test runs on, so the part that can
        /// rot unnoticed is the substitute name itself.
        @Test func everyLegacySymbolNameResolves() {
            let unresolved = SPFKSymbol.allCases
                .compactMap(\.legacySymbolName)
                .filter { NSImage(systemSymbolName: $0, accessibilityDescription: nil) == nil }

            #expect(unresolved.isEmpty, "unresolvable legacy symbol names: \(unresolved)")
        }

        /// The fallback path cannot be reached on a current system, so it is entered by simulating
        /// an older one. This is what proves every substitute renders, rather than only that its
        /// name is spelled correctly.
        @Test func everySymbolResolvesOnTheOldestSupportedSystem() {
            OSVersion.simulatedUnavailableFrom = .macOS14
            defer { OSVersion.simulatedUnavailableFrom = nil }

            let unresolved = SPFKSymbol.allCases
                .filter { $0.nsImage == nil || $0.tinted(color: .white) == nil }
                .map(\.systemSymbolName)

            #expect(unresolved.isEmpty, "unresolvable on macOS 13: \(unresolved)")
        }

        /// A fallback is chosen per version, not for the whole table at once.
        @Test func onlySymbolsPastTheSimulatedVersionFallBack() {
            OSVersion.simulatedUnavailableFrom = .macOS26
            defer { OSVersion.simulatedUnavailableFrom = nil }

            #expect(SPFKSymbol.finder.systemSymbolName == "folder")
            #expect(SPFKSymbol.waveformMid.systemSymbolName == "waveform")
            #expect(SPFKSymbol.document.systemSymbolName == SPFKSymbol.document.rawValue)
            #expect(SPFKSymbol.play.systemSymbolName == SPFKSymbol.play.rawValue)
        }

        /// The failure mode above, caught at the character level rather than through AppKit: an
        /// invisible character is indistinguishable from a correct name by reading.
        @Test func noSymbolNameCarriesAnInvisibleCharacter() {
            let offenders = SPFKSymbol.allCases
                .filter { symbol in
                    symbol.systemSymbolName.unicodeScalars.contains { !$0.isASCII }
                }
                .map { symbol in
                    "\(symbol): \(symbol.systemSymbolName.unicodeScalars.map { "U+\(String($0.value, radix: 16, uppercase: true))" }.joined(separator: " "))"
                }

            #expect(offenders.isEmpty, "symbol names with non-ASCII characters: \(offenders)")
        }
    }

#endif
