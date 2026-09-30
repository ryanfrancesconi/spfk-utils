// Copyright Ryan Francesconi. All Rights Reserved.

#if os(macOS)
    import AppKit
    import Foundation
    import Testing

    @testable import SPFKUtils

    struct SPFKColorSchemeTests {
        @Test(arguments: [NSAppearance.Name.aqua, .vibrantLight, .accessibilityHighContrastAqua, .accessibilityHighContrastVibrantLight])
        func lightAppearancesAreLight(name: NSAppearance.Name) {
            #expect(SPFKColorScheme(appearanceNamed: name) == .light)
        }

        @Test(arguments: [NSAppearance.Name.darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark])
        func darkAppearancesAreDark(name: NSAppearance.Name) {
            #expect(SPFKColorScheme(appearanceNamed: name) == .dark)
        }
    }
#endif
