#if canImport(AppKit) && !targetEnvironment(macCatalyst)

    import AppKit
    import Foundation
    import SwiftUI

    /// Not to be confused with the SwiftUI version
    public enum SPFKColorScheme: String {
        case dark
        case light

        public init(appearanceNamed name: NSAppearance.Name) {
            self = name == .aqua ? .light : .dark
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
