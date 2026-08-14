// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import AppKit
    import UniformTypeIdentifiers

    extension NSWorkspace {
        /// Cache these common types as `CGImage`s
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

            /// The system icon for a URL's file type, cached by path extension.
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

                let icon = NSWorkspace.shared.icon(for: utType)
                byPathExtension[pathExtension] = icon

                return icon
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
