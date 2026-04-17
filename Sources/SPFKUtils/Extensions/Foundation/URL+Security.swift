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
    extension URL {
        /// Returns `true` if the file at this URL can be accessed (exists and is readable).
        public var isAuthorized: Bool {
            FileManager.default.isReadableFile(atPath: path)
        }
    }
#endif
