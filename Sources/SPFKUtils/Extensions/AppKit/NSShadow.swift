// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit

    extension NSShadow {
        public static var basicShadow: NSShadow {
            let shadow = NSShadow()
            shadow.shadowBlurRadius = 5
            shadow.shadowOffset = CGSize(width: 2, height: -2)
            shadow.shadowColor = NSColor.black.withAlphaComponent(0.7)
            return shadow
        }

        public static var glowShadow: NSShadow {
            let shadow = NSShadow()
            shadow.shadowBlurRadius = 8
            shadow.shadowOffset = CGSize.zero
            shadow.shadowColor = NSColor.white.withAlphaComponent(0.7)
            return shadow
        }

        public static var dropShadow: NSShadow {
            let shadow = NSShadow()
            shadow.shadowBlurRadius = 4
            shadow.shadowOffset = CGSize(width: 2, height: -2)
            shadow.shadowColor = NSColor.black.withAlphaComponent(0.4)
            return shadow
        }
    }
#endif
