// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import AppKit
    import SPFKBase

    extension NSWindow {
        public var titlebarHeight: CGFloat {
            frame.height - contentRect(forFrameRect: frame).height
        }

        public var isModal: Bool {
            (isModalPanel || isSheet) && isVisible
        }

        public func clampToScreen(preferredRect: NSRect? = nil, to screen: NSScreen? = nil, animate: Bool = true) {
            guard let screen = screen ?? NSScreen.best else {
                Log.error("Failed to get a valid screen - this is unusual")
                return
            }

            let windowRect = preferredRect ?? frame
            let clampedFrame = screen.clamp(windowRect: windowRect)
            setFrame(clampedFrame, display: true, animate: animate)
        }
    }
#endif
