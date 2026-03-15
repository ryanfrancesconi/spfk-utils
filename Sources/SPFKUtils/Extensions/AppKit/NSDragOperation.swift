// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import AppKit
    import SPFKBase

    extension NSDragOperation {
        public var description: String {
            switch self {
            case .copy:
                "copy (\(rawValue))"
            case .link:
                "link (\(rawValue))"
            case .generic:
                "generic (\(rawValue))"
            case .private:
                "private (\(rawValue))"
            case .move:
                "move (\(rawValue))"
            case .delete:
                "delete (\(rawValue))"
            case .every:
                "every (\(rawValue))"
            case []:
                "none (\(rawValue))"
            default:
                "unknown (\(rawValue))"
            }
        }

        /// Checks the global option key to decide between move or copy operations
        /// - Returns: a suggested `NSDragOperation` value
        public static func copyOrMove() -> NSDragOperation {
            NSEvent.modifierFlags.contains(.option) ? .copy : .move
        }
    }
#endif
