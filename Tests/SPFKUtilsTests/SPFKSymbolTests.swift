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

        /// A symbol added from a current SF Symbols release resolves on this machine, so nothing
        /// else here notices that it needs a fallback — simulating an older OS only changes which
        /// name is requested, not whether the raw value exists. Asks the system what release each
        /// raw value came from instead of restating a list that would rot.
        @Test func everySymbolNewerThanTheDeploymentFloorDeclaresAFallback() throws {
            let availability = try Self.macOSVersionBySymbolName()

            var missing: [String] = []

            for symbol in SPFKSymbol.allCases where symbol.legacySymbolName == nil {
                guard let introduced = availability[symbol.rawValue] else {
                    missing.append("\(symbol): '\(symbol.rawValue)' names no known symbol")
                    continue
                }

                if introduced > Self.deploymentFloor {
                    missing.append(
                        "\(symbol): '\(symbol.rawValue)' needs macOS "
                            + "\(introduced.majorVersion).\(introduced.minorVersion)"
                    )
                }
            }

            #expect(missing.isEmpty, "symbols needing a legacySymbolName: \(missing)")
        }

        /// The fallback table and the version gate are separate switches, so an entry added to one
        /// and not the other is silent: the name exists and is never reached.
        @Test func everyFallbackIsReachedWhenItsVersionIsUnavailable() {
            OSVersion.simulatedUnavailableFrom = .macOS14
            defer { OSVersion.simulatedUnavailableFrom = nil }

            let unreachable = SPFKSymbol.allCases
                .filter { $0.legacySymbolName != nil && $0.systemSymbolName == $0.rawValue }
                .map(\.rawValue)

            #expect(unreachable.isEmpty, "legacySymbolName never reached for: \(unreachable)")
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

        // MARK: - Helpers

        /// `SPFKUtils` declares `.macOS(.v13)`, which is what `legacySymbolName` promises to reach.
        private static let deploymentFloor = OperatingSystemVersion(
            majorVersion: 13, minorVersion: 0, patchVersion: 0
        )

        /// The macOS release each SF Symbol name was introduced in, read from the glyph bundle the
        /// system resolves names against. Fails loudly if Apple moves or reshapes it, rather than
        /// passing on an empty table.
        private static func macOSVersionBySymbolName() throws -> [String: OperatingSystemVersion] {
            let url = URL(
                fileURLWithPath: "/System/Library/CoreServices/CoreGlyphs.bundle"
                    + "/Contents/Resources/name_availability.plist"
            )

            let plist = try PropertyListSerialization.propertyList(
                from: try Data(contentsOf: url), format: nil
            )

            guard let root = plist as? [String: Any],
                  let releaseByName = root["symbols"] as? [String: String],
                  let platformsByRelease = root["year_to_release"] as? [String: [String: String]]
            else {
                throw SymbolAvailabilityError.unexpectedLayout(url)
            }

            return releaseByName.compactMapValues { release in
                platformsByRelease[release]?["macOS"].flatMap(Self.version)
            }
        }

        private static func version(_ string: String) -> OperatingSystemVersion? {
            let parts = string.split(separator: ".").compactMap { Int($0) }
            guard let major = parts.first else { return nil }

            return OperatingSystemVersion(
                majorVersion: major,
                minorVersion: parts.count > 1 ? parts[1] : 0,
                patchVersion: parts.count > 2 ? parts[2] : 0
            )
        }
    }

    private enum SymbolAvailabilityError: Error {
        case unexpectedLayout(URL)
    }

    extension OperatingSystemVersion {
        fileprivate static func > (lhs: Self, rhs: Self) -> Bool {
            (lhs.majorVersion, lhs.minorVersion, lhs.patchVersion)
                > (rhs.majorVersion, rhs.minorVersion, rhs.patchVersion)
        }
    }

#endif
