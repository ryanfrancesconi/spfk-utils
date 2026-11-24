// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKBase

/// The folder a run renders its folders under, checked once when it is chosen.
public struct MoveRoot: Sendable, Hashable {
    public let url: URL

    /// The mount point of the root's volume. A file on another volume stays where it is.
    public let volume: URL?

    /// Whether the root's volume compares names by case. Every folder under the root, made or not
    /// yet made, is taken to share it.
    public let isCaseSensitive: Bool

    init(url: URL, volume: URL?, isCaseSensitive: Bool) {
        self.url = url.standardizedFileURL
        self.volume = volume
        self.isCaseSensitive = isCaseSensitive
    }
}
