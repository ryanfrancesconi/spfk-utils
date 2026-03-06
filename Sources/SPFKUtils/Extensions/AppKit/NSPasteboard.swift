// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

extension NSPasteboard.PasteboardType {
    /// this is deprecated, file paths from finder
    public static let filenames = Self("NSFilenamesPboardType")
}
#endif
