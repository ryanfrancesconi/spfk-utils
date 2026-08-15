// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import AppKit

    extension NSScreen {
        public var readableDescription: String {
            var out = localizedName

            if self == NSScreen.main {
                out += " (Main 🖥)"
            }

            out += ", frame: \(frame), visible: \(visibleFrame)"
            out += ", Refresh Rate: \(maximumFramesPerSecond) hz, Interval: \(maximumRefreshInterval)"
            return out
        }

        public static var menubarScreen: NSScreen? {
            screens.first
        }

        public static var best: NSScreen? {
            menubarScreen ?? main
        }

        /// Fits `rect` inside `visibleFrame`: resized only when it is larger than the screen,
        /// otherwise moved. Split from ``clamp(windowRect:)`` so it can be tested without a display.
        static func clamp(_ rect: NSRect, within visibleFrame: NSRect) -> NSRect {
            var result = rect

            // Size first: capping it is what guarantees the origin range below is non-empty.
            result.size.width = min(result.width, visibleFrame.width)
            result.size.height = min(result.height, visibleFrame.height)

            result.origin.x = min(max(result.minX, visibleFrame.minX), visibleFrame.maxX - result.width)
            result.origin.y = min(max(result.minY, visibleFrame.minY), visibleFrame.maxY - result.height)

            return result
        }

        public func clamp(windowRect rect: NSRect) -> NSRect {
            Self.clamp(rect, within: visibleFrame)
        }
    }

    extension NSScreen {
        /// Clamp to both main and menubar screens, which are generally the same screen.
        public static func clamp(size: NSSize) -> NSSize {
            var size = size

            for screen in [NSScreen.main, NSScreen.menubarScreen].compactMap({ $0 }) {
                size.width = min(size.width, screen.visibleFrame.width)
                size.height = min(size.height, screen.visibleFrame.height)
            }

            return size
        }
    }

#endif
