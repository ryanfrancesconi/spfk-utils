// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils
// swiftformat:disable consecutiveSpaces

#if os(macOS)

    import AppKit
    import Foundation

    /// The two neutral scheme grays symbol tinting renders against.
    ///
    /// These live here rather than with the rest of the color system in `SPFKUI` because
    /// `SPFKSymbol.tinted()` and `NSImageConvertible.stateImage()` use them as default arguments,
    /// and both are reachable from data packages (`spfk-playlist-data`, `spfk-torchtag-data`) that
    /// depend on `spfk-utils` and cannot depend on `SPFKUI` — `spfk-ui` already depends on
    /// `spfk-playlist-data`, so the reverse edge would be a cycle.
    ///
    /// `SPFKColor.schemeColor` / `.schemeColorAlternate` resolve to these, so there is one definition.
    public enum SPFKSchemeColor {
        case primary
        case alternate

        public var light: NSColor {
            switch self {
            case .primary:   #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
            case .alternate: #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
            }
        }

        public var dark: NSColor {
            switch self {
            case .primary:   #colorLiteral(red: 0.8974402547, green: 0.8974402547, blue: 0.8974403739, alpha: 1)
            case .alternate: #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            }
        }

        /// Dynamic NSColor that auto-resolves based on the current appearance context.
        public var nsColor: NSColor {
            NSColor(name: nil) { [self] appearance in
                let name = appearance.bestMatch(from: [.aqua, .darkAqua]) ?? .darkAqua
                return name == .aqua ? light : dark
            }
        }

        /// Resolved CGColor for the current appearance context.
        public var cgColor: CGColor { nsColor.cgColor }
    }

#endif
// swiftformat:enable consecutiveSpaces
