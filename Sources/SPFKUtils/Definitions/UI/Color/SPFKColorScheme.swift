// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)

    import AppKit
    import Foundation
    import SwiftUI

    /// Not to be confused with the SwiftUI version
    public enum SPFKColorScheme: String {
        case dark
        case light

        /// Resolves through AppKit's own matching, so the high-contrast and vibrant variants
        /// follow the appearance they derive from.
        public init(appearanceNamed name: NSAppearance.Name) {
            let match = NSAppearance(named: name)?.bestMatch(from: [.aqua, .darkAqua])
            self = match == .darkAqua ? .dark : .light
        }

        public init(colorScheme: SwiftUI.ColorScheme) {
            self = colorScheme == .light ? .light : .dark
        }

        @MainActor
        public static var currentScheme: SPFKColorScheme {
            guard let name = NSApp?.effectiveAppearance.name else {
                return .dark
            }

            return SPFKColorScheme(appearanceNamed: name)
        }
    }

#endif
