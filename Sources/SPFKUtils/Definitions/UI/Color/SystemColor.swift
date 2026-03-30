// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)

    import Foundation

    import AppKit

    extension CGColor {
        public static var systemRed: CGColor { NSColor.systemRed.cgColor }
        public static var systemGreen: CGColor { NSColor.systemGreen.cgColor }
        public static var systemBlue: CGColor { NSColor.systemBlue.cgColor }
        public static var systemOrange: CGColor { NSColor.systemOrange.cgColor }
        public static var systemYellow: CGColor { NSColor.systemYellow.cgColor }
        public static var systemBrown: CGColor { NSColor.systemBrown.cgColor }
        public static var systemPink: CGColor { NSColor.systemPink.cgColor }
        public static var systemPurple: CGColor { NSColor.systemPurple.cgColor }
        public static var systemGray: CGColor { NSColor.systemGray.cgColor }
        public static var systemTeal: CGColor { NSColor.systemTeal.cgColor }
        public static var systemIndigo: CGColor { NSColor.systemIndigo.cgColor }
        public static var systemMint: CGColor { NSColor.systemMint.cgColor }
        public static var systemCyan: CGColor { NSColor.systemCyan.cgColor }
    }

    public enum SystemColor {
        case red
        case green
        case blue
        case orange
        case yellow
        case brown
        case pink
        case purple
        case gray
        case teal
        case indigo
        case mint
        case cyan

        public var cgColor: CGColor {
            switch self {
            case .red: .systemRed
            case .green: .systemGreen
            case .blue: .systemBlue
            case .orange: .systemOrange
            case .yellow: .systemYellow
            case .brown: .systemBrown
            case .pink: .systemPink
            case .purple: .systemPurple
            case .gray: .systemGray
            case .teal: .systemTeal
            case .indigo: .systemIndigo
            case .mint: .systemMint
            case .cyan: .systemCyan
            }
        }

        public var nsColor: NSColor {
            switch self {
            case .red: .systemRed
            case .green: .systemGreen
            case .blue: .systemBlue
            case .orange: .systemOrange
            case .yellow: .systemYellow
            case .brown: .systemBrown
            case .pink: .systemPink
            case .purple: .systemPurple
            case .gray: .systemGray
            case .teal: .systemTeal
            case .indigo: .systemIndigo
            case .mint: .systemMint
            case .cyan: .systemCyan
            }
        }
    }

#endif
