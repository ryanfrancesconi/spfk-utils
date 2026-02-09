// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
    import UniformTypeIdentifiers

    extension NSWorkspace {
        /// Cache these common types as `CGImage`s
        public enum FinderIcon {
            /// Any audio and/or video content.
            public static let media: CGImage? = NSWorkspace.shared.icon(for: .audiovisualContent).cgImage

            /// Pure audio data with no video data.
            public static let audio: CGImage? = NSWorkspace.shared.icon(for: .audio).cgImage

            /// Pure video data with no audio data.
            public static let video: CGImage? = NSWorkspace.shared.icon(for: .video).cgImage

            /// A base type for abstract image data.
            public static let image: CGImage? = NSWorkspace.shared.icon(for: .image).cgImage
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
