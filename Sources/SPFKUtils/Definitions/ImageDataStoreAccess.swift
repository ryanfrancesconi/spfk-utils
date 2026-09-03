// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import CoreGraphics
import Foundation
import UniformTypeIdentifiers

public protocol ImageDataStoreAccess: Sendable {
    func insertImage(_ type: CachedImageType, cgImage: CGImage, for url: URL) async throws
    func fetchImage(_ type: CachedImageType, for url: URL) async -> CGImage?
    func imageExists(for url: URL) async -> Bool

    /// When the cached image for `url` was written, or nil when nothing is cached. Compared
    /// against the file's own modification date by a caller whose files can be rewritten in
    /// place -- entries are keyed by URL with no content fingerprint.
    func imageCacheDate(_ type: CachedImageType, for url: URL) async -> Date?

    /// Drops every cached image for one file.
    func deleteImages(for url: URL) async

    @discardableResult
    func pruneImages(activeURLs: Set<URL>) async -> Int
}
