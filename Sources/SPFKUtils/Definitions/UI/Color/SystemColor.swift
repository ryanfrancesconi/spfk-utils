// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)

    import Foundation

    import AppKit

    extension CGColor {
        public static let systemRed: CGColor = NSColor.systemRed.cgColor
        public static let systemGreen: CGColor = NSColor.systemGreen.cgColor
        public static let systemBlue: CGColor = NSColor.systemBlue.cgColor
        public static let systemOrange: CGColor = NSColor.systemOrange.cgColor
        public static let systemYellow: CGColor = NSColor.systemYellow.cgColor
        public static let systemBrown: CGColor = NSColor.systemBrown.cgColor
        public static let systemPink: CGColor = NSColor.systemPink.cgColor
        public static let systemPurple: CGColor = NSColor.systemPurple.cgColor
        public static let systemGray: CGColor = NSColor.systemGray.cgColor
        public static let systemTeal: CGColor = NSColor.systemTeal.cgColor
        public static let systemIndigo: CGColor = NSColor.systemIndigo.cgColor
        public static let systemMint: CGColor = NSColor.systemMint.cgColor
        public static let systemCyan: CGColor = NSColor.systemCyan.cgColor
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
