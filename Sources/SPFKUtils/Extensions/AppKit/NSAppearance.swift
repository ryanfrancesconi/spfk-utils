// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
import AppKit

@MainActor
extension NSAppearance {
    public static let dark = NSAppearance(named: .darkAqua)
}
#endif
