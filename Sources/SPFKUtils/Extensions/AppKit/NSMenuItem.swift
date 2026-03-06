// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

extension NSMenuItem {
    // seems like an init that should already exist
    @objc public convenience init(
        title: String,
        action: Selector? = nil,
        target: AnyObject? = nil,
        keyEquivalent: String = "",
        keyEquivalentModifierMask: NSEvent.ModifierFlags = []
    ) {
        self.init(
            title: title,
            action: action,
            keyEquivalent: keyEquivalent
        )

        self.target = target
        self.keyEquivalentModifierMask = keyEquivalentModifierMask
    }
}
#endif
