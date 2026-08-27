// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import CoreGraphics
import Foundation
import UniformTypeIdentifiers

public protocol ImageDataStoreAccess: Sendable {
    func insertImage(_ type: CachedImageType, cgImage: CGImage, for url: URL) async throws
    func fetchImage(_ type: CachedImageType, for url: URL) async -> CGImage?
    func imageExists(for url: URL) async -> Bool

    @discardableResult
    func pruneImages(activeURLs: Set<URL>) async -> Int
}
