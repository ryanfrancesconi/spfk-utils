// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKBase

extension URL {
    public func isParent(of otherURL: URL) -> Bool {
        guard isDirectory else { return false }

        return otherURL.path.hasPrefix(path)
    }
}

#if os(macOS)
    import AppKit

    extension URL {
        /// Checks for NSFileReadUnknownError when accessing via security scope
        public var isAuthorized: Bool {
            do {
                // throws error if unable to get data, lack of security access
                _ = try bookmarkData(options: [.withSecurityScope])
                return true
            } catch {
                Log.error(error)
                return false
            }
        }
    }

    extension URL {
        @MainActor
        public func authorize() throws {
            let panel = NSOpenPanel()
            panel.message = localized("Please allow access to this directory by choosing Open...")
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            panel.directoryURL = isDirectory ? self : deletingLastPathComponent()

            guard panel.runModal() == .OK else {
                throw NSError(description: "Need to say OK")
            }

            guard let authorizedURL = panel.url else {
                throw NSError(description: "URL is nil")
            }

            guard authorizedURL == self || authorizedURL.isParent(of: self) else {
                throw NSError(description: "Chose incorrect URL: \(authorizedURL.path)")
            }
        }
    }
#endif
