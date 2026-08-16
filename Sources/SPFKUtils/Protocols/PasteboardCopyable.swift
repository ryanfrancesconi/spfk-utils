// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

@MainActor public protocol PasteboardCopyable {
    /// - Returns: whether anything was written. A copy with nothing to copy leaves the user's
    ///   existing clipboard alone, and a caller confirming the action needs to tell the two apart.
    @discardableResult
    func copyToPasteboard() throws -> Bool

    func pasteFromPasteboard() throws
}
