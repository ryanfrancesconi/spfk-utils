// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
import AppKit

extension NSPasteboard.PasteboardType {
    /// this is deprecated, file paths from finder
    public static let filenames = Self("NSFilenamesPboardType")
}

extension NSPasteboard {
    /// Replaces the contents with the POSIX paths of `urls`, one per line.
    ///
    /// Writes nothing for an empty array: a copy with nothing to copy must leave whatever the user
    /// already had on the clipboard alone.
    public func write(paths urls: [URL]) {
        guard urls.isNotEmpty else { return }

        clearContents()
        declareTypes([.string], owner: nil)
        setString(urls.map(\.path).joined(separator: "\n"), forType: .string)
    }
}
#endif
