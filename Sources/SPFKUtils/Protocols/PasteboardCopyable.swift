// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

@MainActor public protocol PasteboardCopyable {
    func copyToPasteboard() throws
    func pasteFromPasteboard() throws
}
