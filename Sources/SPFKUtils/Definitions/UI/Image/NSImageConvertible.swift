// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)

    import AppKit
    import Foundation

    public protocol NSImageConvertible {
        var nsImage: NSImage? { get }
        var nsImageAlternate: NSImage? { get }
    }

    extension NSImageConvertible {
        public var nsImageAlternate: NSImage? { nsImage }

        public func tinted(color: NSColor) -> NSImage? {
            nsImage?.tinted(color: color)
        }

        public func stateImage(
            offColor: NSColor = SPFKColor.schemeColorAlternate.nsColor,
            onColor: NSColor = SPFKColor.schemeColor.nsColor,
            size: NSSize? = nil
        ) -> StateImage {
            guard let on = nsImageAlternate?.tinted(color: onColor),
                  let off = tinted(color: offColor) else { return .init() }

            if let size, let on_s = on.copy(size: size), let off_s = off.copy(size: size) {
                return .init(image: off_s, alternateImage: on_s)
            }

            return .init(image: off, alternateImage: on)
        }
    }

#endif
