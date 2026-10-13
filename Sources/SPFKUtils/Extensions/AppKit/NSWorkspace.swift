// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import AppKit
    import UniformTypeIdentifiers

    extension NSWorkspace {
        /// Cache these common types as `NSImage`s
        public enum FinderIcon {
            /// Any audio and/or video content.
            public static let media: NSImage? = NSWorkspace.shared.icon(for: .audiovisualContent)

            /// Pure audio data with no video data.
            public static let audio: NSImage? = NSWorkspace.shared.icon(for: .audio)

            /// Pure video data with no audio data.
            public static let video: NSImage? = NSWorkspace.shared.icon(for: .video)

            /// A base type for abstract image data.
            public static let image: NSImage? = NSWorkspace.shared.icon(for: .image)

            @MainActor
            private static var byPathExtension: [String: NSImage] = [:]

            @MainActor
            private static var bitmapsByIcon: [ObjectIdentifier: NSImage] = [:]

            /// `icon` drawn once into a 32 pt bitmap at 2x, for an image view to show.
            ///
            /// A system icon is resolved by IconServices in every image view it is set on: 0.42 ms per
            /// view, against 0.048 ms for a bitmap (`-O`, 2026-10-12). Drawing one costs ~13 ms, once.
            @MainActor
            public static func bitmap(of icon: NSImage) -> NSImage {
                let points: CGFloat = 32
                let pixels = Int(points * 2)

                guard let rep = NSBitmapImageRep(
                    bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
                    samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                    bytesPerRow: 0, bitsPerPixel: 0
                ) else { return icon }

                rep.size = NSSize(width: points, height: points)

                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
                icon.draw(in: NSRect(x: 0, y: 0, width: points, height: points))
                NSGraphicsContext.restoreGraphicsState()

                let image = NSImage(size: rep.size)
                image.addRepresentation(rep)
                return image
            }

            /// ``bitmap(of:)`` for a long-lived icon, drawn the first time it is asked for.
            @MainActor
            private static func cachedBitmap(of icon: NSImage) -> NSImage {
                let key = ObjectIdentifier(icon)
                if let cached = bitmapsByIcon[key] { return cached }

                let drawn = bitmap(of: icon)
                bitmapsByIcon[key] = drawn
                return drawn
            }

            /// The system icon for a URL's file type, as a bitmap, cached by path extension.
            ///
            /// Resolved from the extension's `UTType` rather than the file itself, so this touches
            /// no file system and is safe to call per row per reload. `icon(forFile:)` returns the
            /// same image for any file without a custom icon; a file that has one shows its type's
            /// icon here instead.
            @MainActor
            public static func fileType(for url: URL) -> NSImage? {
                let pathExtension = url.pathExtension.lowercased()

                guard pathExtension.isEmpty == false else { return nil }

                if let cached = byPathExtension[pathExtension] {
                    return cached
                }

                guard let utType = UTType(filenameExtension: pathExtension) else { return nil }

                let icon = bitmap(of: NSWorkspace.shared.icon(for: utType))
                byPathExtension[pathExtension] = icon

                return icon
            }

            /// A thumbnail when there is one, else the system icon for the URL's type, else
            /// `fallback` -- the order every file cell draws in, so a file's image does not depend on
            /// which table shows it. Icons come back as bitmaps; `fallback` must outlive the call,
            /// since its bitmap is cached by identity.
            @MainActor
            public static func fileImage(for url: URL, thumbnail: NSImage?, fallback: NSImage?) -> NSImage? {
                thumbnail ?? fileType(for: url) ?? fallback.map(cachedBitmap(of:))
            }
        }

        public static func showInFinder(urls: [URL]) {
            let urls = urls.filter { FileManager.default.fileExists(atPath: $0.path) }

            let directories = urls.filter { $0.isDirectory && !$0.isPackage }
            let files = urls.filter { !$0.isDirectory || $0.isPackage }

            for item in directories {
                NSWorkspace.shared.open(item)
            }

            if files.isNotEmpty {
                NSWorkspace.shared.activateFileViewerSelecting(files)
            }
        }
    }
#endif
