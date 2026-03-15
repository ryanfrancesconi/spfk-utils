// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import AppKit

    extension URL {
        /// Low resolution finder image
        @_disfavoredOverload public var finderIcon: NSImage? {
            guard isFileURL, exists else { return nil }

            return NSWorkspace.shared.icon(forFile: path)
        }

        /// Higher resolution finder image
        @_disfavoredOverload public var bestImageRepresentation: NSImage? {
            guard isFileURL, exists else { return nil }

            let size = NSSize(equal: 1024)

            guard let rep = NSWorkspace.shared.icon(
                forFile: path
            ).bestRepresentation(
                for: NSRect(size: size),
                context: nil,
                hints: nil
            ) else { return nil }

            let image = NSImage(size: size)

            image.addRepresentation(rep)

            return image
        }

        @_disfavoredOverload
        public var contentTypeIcon: NSImage? {
            guard isFileURL, exists, let utType else { return nil }

            return NSWorkspace.shared.icon(for: utType)
        }
    }
#endif
