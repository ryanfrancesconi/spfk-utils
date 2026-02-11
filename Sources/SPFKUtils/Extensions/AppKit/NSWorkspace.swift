// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
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
