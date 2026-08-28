// Copyright Ryan Francesconi. All Rights Reserved.

#if os(macOS)

    import AppKit
    import Foundation
    import SPFKUtils
    import Testing

    /// Whether every symbol name actually names a symbol.
    ///
    /// `nsImage` returns `nil` for a name AppKit cannot resolve, and nothing above it reports that
    /// — a menu item just renders with no icon. `linesDecrease` carried three `U+200B` zero-width
    /// spaces inside its raw value and had been unresolvable for as long as it existed; the name
    /// reads correctly at every glance, which is exactly why it survived.
    @Suite
    struct SPFKSymbolTests {
        @Test func everySymbolResolves() {
            let unresolved = SPFKSymbol.allCases
                .filter { $0.nsImage == nil }
                .map(\.systemSymbolName)

            #expect(unresolved.isEmpty, "unresolvable symbol names: \(unresolved)")
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
