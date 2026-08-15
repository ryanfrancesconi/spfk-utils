// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import AppKit

    extension NSWindow {
        public var titlebarHeight: CGFloat {
            frame.height - contentRect(forFrameRect: frame).height
        }

        public var isModal: Bool {
            (isModalPanel || isSheet) && isVisible
        }
    }
#endif
