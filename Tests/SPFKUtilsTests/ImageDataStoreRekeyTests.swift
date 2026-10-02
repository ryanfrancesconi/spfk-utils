// Copyright Ryan Francesconi. All Rights Reserved.

import CoreGraphics
import Foundation
import SPFKBase
import SPFKImage
import SPFKTesting
import Testing
import UniformTypeIdentifiers

@testable import SPFKUtils

/// A relinked file keeps its cached images under the new path's key.
@MainActor
@Suite(.tags(.file))
final class ImageDataStoreRekeyTests: BinTestCase {
    private func image(red: CGFloat) throws -> CGImage {
        let context = try #require(CGContext(
            data: nil, width: 64, height: 64, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(red: red, green: 0, blue: 0, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
        let raw = try #require(context.makeImage())
        return try CGImage.create(from: raw.dataRepresentation(utType: .png))
    }

    private func makeStore() throws -> ImageDataStore {
        deleteBinOnExit = true
        return try ImageDataStore(inDirectory: bin)
    }

    private let old = URL(fileURLWithPath: "/Old Drive/Pictures/a.jpg")
    private let new = URL(fileURLWithPath: "/New Drive/Pictures/a.jpg")

    @Test func bothTiersMoveToTheNewKey() async throws {
        let store = try makeStore()

        try await store.insert(.thumbnail, cgImage: image(red: 1), for: old)
        try await store.insert(.fullQuality, cgImage: image(red: 1), for: old)

        try await store.rekey(from: old, to: new)

        #expect(await store.fetch(.thumbnail, for: new) != nil)
        #expect(await store.fetch(.fullQuality, for: new) != nil)
        #expect(await store.fetch(.thumbnail, for: old) == nil)
        #expect(await store.fetch(.fullQuality, for: old) == nil)
    }

    /// The moved entry must read as no older than the file it now describes, or the first fetch
    /// throws it away as stale.
    @Test func theMovedEntryIsStampedNow() async throws {
        let store = try makeStore()
        try await store.insert(.thumbnail, cgImage: image(red: 1), for: old)

        let before = Date()
        try await store.rekey(from: old, to: new)

        let stamped = try #require(await store.cacheDate(.thumbnail, for: new))
        #expect(stamped >= before.addingTimeInterval(-1))
    }

    /// On a merge the file already in the library keeps its own images.
    @Test func anExistingEntryAtTheNewKeyWins() async throws {
        let store = try makeStore()

        try await store.insert(.thumbnail, cgImage: image(red: 1), for: old)
        try await store.insert(.thumbnail, cgImage: image(red: 0.5), for: new)
        let existing = try #require(await store.fetch(.thumbnail, for: new)).fingerprint

        try await store.rekey(from: old, to: new)

        #expect(try #require(await store.fetch(.thumbnail, for: new)).fingerprint == existing)
        #expect(await store.fetch(.thumbnail, for: old) == nil)
        #expect(await store.count() == 1)
    }

    /// Two keys sharing pixels share one inode; stamping a move must not reach the other key.
    @Test func aHardlinkedEntryKeepsItsOwnDate() async throws {
        let store = try makeStore()
        let other = URL(fileURLWithPath: "/Old Drive/Pictures/b.jpg")
        let pixels = try image(red: 1)

        try await store.insert(.thumbnail, cgImage: pixels, for: other)
        try await store.insert(.thumbnail, cgImage: pixels, for: old)
        let otherDate = try #require(await store.cacheDate(.thumbnail, for: other))

        try await Task.sleep(for: .milliseconds(20))
        try await store.rekey(from: old, to: new)

        #expect(await store.cacheDate(.thumbnail, for: other) == otherDate)
        #expect(await store.fetch(.thumbnail, for: other) != nil)
    }
}
