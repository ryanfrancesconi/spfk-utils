// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
import AppKit

extension NSButton.ButtonType {
    public var isToggle: Bool {
        switch self {
        case .pushOnPushOff, .toggle, .switch, .onOff:
            return true

        default:
            return false
        }
    }
}
#endif
