// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import AppKit
    import SPFKBase
    import SPFKFileSystem

    extension FileSystem {
        @MainActor
        public static func authorizedFileURLs(at url: URL, showOpenPanel: Bool = true) async throws -> [URL] {
            if showOpenPanel {
                try url.authorize() // will open panel to select
            }

            return FileSystem.enumerateFiles(
                in: url,
                recursive: true
            ).filter(\.isAuthorized)
        }

        @MainActor
        public static func requestDirectory(message: String?, directoryURL: URL?) -> URL? {
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            panel.title = message ?? "Please select a directory"
            panel.directoryURL = directoryURL

            guard panel.runModal() == .OK,
                  let url = panel.url else { return nil }

            return url
        }
    }
#endif
