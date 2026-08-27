// Copyright Ryan Francesconi. All Rights Reserved.

import CoreGraphics
import Foundation
import SPFKBase
import SPFKTesting
import Testing
import UniformTypeIdentifiers

@testable import SPFKUtils

@MainActor
@Suite(.tags(.file))
final class ImageDataStoreTests: BinTestCase {
    // MARK: - Helpers

    /// Creates a synthetic CGImage round-tripped through the given format
    /// so that `cgImage.utType` is set (required by `insertPrimary`).
    private func syntheticImage(
        width: Int = 200,
        height: Int = 200,
        utType: UTType = .jpeg
    ) throws -> CGImage {
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let raw = context.makeImage()!
        let data = try raw.dataRepresentation(utType: utType)
        return try CGImage.create(from: data)
    }

    private func fakeURL(index: Int) -> URL {
        URL(string: "file:///fake/audio/track_\(index).mp3")!
    }

    /// Inserts both primary and thumbnail for a given image (mirrors cacheImages behavior).
    private func insertBoth(
        _ store: ImageDataStore,
        cgImage: CGImage,
        thumbnail: CGImage? = nil,
        url: URL
    ) async throws {
        try await store.insert(.fullQuality, cgImage: cgImage, for: url)
        let thumb = thumbnail ?? cgImage.scaled(to: CGSize(width: 32, height: 32))!
        try await store.insert(.thumbnail, cgImage: thumb, for: url)
    }

    // MARK: - Tests

    @Test func insertAndFetchThumbnail() async throws {
        deleteBinOnExit = true
        let store = try ImageDataStore(inDirectory: bin)
        let url = fakeURL(index: 0)

        try await insertBoth(store, cgImage: try syntheticImage(), url: url)

        let thumb = await store.fetch(.thumbnail, for: url)
        #expect(thumb != nil)
        #expect(thumb?.width == 32)
        #expect(thumb?.height == 32)
    }

    @Test func insertAndFetchFullJPEG() async throws {
        deleteBinOnExit = true
        let store = try ImageDataStore(inDirectory: bin)
        let url = fakeURL(index: 1)

        try await insertBoth(store, cgImage: try syntheticImage(), url: url)

        let full = await store.fetch(.fullQuality, for: url)
        #expect(full != nil)
        #expect(full?.width == 200)
        #expect(full?.height == 200)
    }

    @Test func insertAndFetchFullPNG() async throws {
        deleteBinOnExit = true
        let store = try ImageDataStore(inDirectory: bin)
        let url = fakeURL(index: 2)

        try await insertBoth(store, cgImage: try syntheticImage(utType: .png), url: url)

        let full = await store.fetch(.fullQuality, for: url)
        #expect(full != nil)
        #expect(full?.width == 200)
        #expect(full?.height == 200)
    }

    @Test func overwriteFormatChange() async throws {
        deleteBinOnExit = true
        let store = try ImageDataStore(inDirectory: bin)
        let url = fakeURL(index: 3)

        // Insert as JPEG
        let jpegImage = try syntheticImage(utType: .jpeg)
        try await insertBoth(store, cgImage: jpegImage, url: url)
        #expect(await store.fetch(.fullQuality, for: url) != nil)

        // Re-insert as PNG — old .jpg should be deleted
        let pngImage = try syntheticImage(utType: .png)
        try await insertBoth(store, cgImage: pngImage, url: url)

        let key = url.sha256
        let shard = String(key.prefix(2))
        let jpgURL = bin.appendingPathComponent("Data/Image/\(shard)/\(key)_full.jpeg")
        #expect(!FileManager.default.fileExists(atPath: jpgURL.path))

        let full = await store.fetch(.fullQuality, for: url)
        #expect(full != nil)
    }

    @Test func existsReturnsTrueAfterInsert() async throws {
        deleteBinOnExit = true
        let store = try ImageDataStore(inDirectory: bin)
        let url = fakeURL(index: 4)
        #expect(await store.exists(url: url) == false)

        try await insertBoth(store, cgImage: try syntheticImage(), url: url)
        #expect(await store.exists(url: url) == true)
    }

    @Test func deleteRemovesFiles() async throws {
        deleteBinOnExit = true
        let store = try ImageDataStore(inDirectory: bin)
        let url = fakeURL(index: 5)

        try await insertBoth(store, cgImage: try syntheticImage(), url: url)
        #expect(await store.exists(url: url))

        await store.delete(url: url)
        #expect(await store.exists(url: url) == false)
        #expect(await store.fetch(.fullQuality, for: url) == nil)
    }

    @Test func deleteAll() async throws {
        deleteBinOnExit = true
        let store = try ImageDataStore(inDirectory: bin)

        for i in 0 ..< 5 {
            try await insertBoth(store, cgImage: try syntheticImage(), url: fakeURL(index: i))
        }
        #expect(await store.count() == 5)

        await store.deleteAll()
        #expect(await store.count() == 0)
    }

    @Test func prune() async throws {
        deleteBinOnExit = true
        let store = try ImageDataStore(inDirectory: bin)
        var urls: [URL] = []

        for i in 0 ..< 10 {
            let url = fakeURL(index: i)
            try await insertBoth(store, cgImage: try syntheticImage(), url: url)
            urls.append(url)
        }

        let activeURLs = Set(urls.prefix(3))
        let removed = await store.prune(activeURLs: activeURLs)
        #expect(removed == 7)
        #expect(await store.count() == 3)
    }

    @Test func emptyStoreCountIsZero() async throws {
        deleteBinOnExit = true
        let store = try ImageDataStore(inDirectory: bin)

        #expect(await store.count() == 0)
    }

    @Test func fetchMissingReturnsNil() async throws {
        deleteBinOnExit = true
        let store = try ImageDataStore(inDirectory: bin)
        let url = fakeURL(index: 99)

        #expect(await store.fetch(.thumbnail, for: url) == nil)
        #expect(await store.fetch(.fullQuality, for: url) == nil)
    }

    @Test func insertWithExplicitThumbnail() async throws {
        deleteBinOnExit = true
        let store = try ImageDataStore(inDirectory: bin)
        let url = fakeURL(index: 10)
        let fullImage = try syntheticImage(width: 400, height: 400, utType: .png)
        let thumbImage = try syntheticImage(width: 32, height: 32)

        try await insertBoth(store, cgImage: fullImage, thumbnail: thumbImage, url: url)

        let thumb = await store.fetch(.thumbnail, for: url)
        #expect(thumb != nil)
        #expect(thumb?.width == 32)

        let full = await store.fetch(.fullQuality, for: url)
        #expect(full != nil)
        #expect(full?.width == 400)
    }

    @Test func insertSingleThumbnail() async throws {
        deleteBinOnExit = true
        let store = try ImageDataStore(inDirectory: bin)
        let url = fakeURL(index: 11)
        let thumbImage = try syntheticImage(width: 32, height: 32)

        try await store.insert(.thumbnail, cgImage: thumbImage, for: url)

        let thumb = await store.fetch(.thumbnail, for: url)
        #expect(thumb != nil)
        #expect(thumb?.width == 32)

        // No primary was inserted
        #expect(await store.fetch(.fullQuality, for: url) == nil)
    }

    @Test func insertSinglePrimary() async throws {
        deleteBinOnExit = true
        let store = try ImageDataStore(inDirectory: bin)
        let url = fakeURL(index: 12)
        let fullImage = try syntheticImage(width: 300, height: 300)

        try await store.insert(.fullQuality, cgImage: fullImage, for: url)

        let full = await store.fetch(.fullQuality, for: url)
        #expect(full != nil)
        #expect(full?.width == 300)

        // No thumbnail was inserted
        #expect(await store.fetch(.thumbnail, for: url) == nil)
    }

    // MARK: - Fingerprint deduplication

    /// Inserting the same CGImage for two different audio URLs should produce two thumbnail
    /// files that share an inode (hardlink), not two independent copies.
    @Test func thumbnailDeduplicatesViaHardlink() async throws {
        deleteBinOnExit = true
        let store = try ImageDataStore(inDirectory: bin)
        let image = try syntheticImage(width: 100, height: 100)
        let url1 = fakeURL(index: 200)
        let url2 = fakeURL(index: 201)

        try await store.insert(.thumbnail, cgImage: image, for: url1)
        try await store.insert(.thumbnail, cgImage: image, for: url2)

        let key1 = url1.sha256
        let key2 = url2.sha256
        let shard1 = String(key1.prefix(2))
        let shard2 = String(key2.prefix(2))
        let file1 = bin.appendingPathComponent("Data/Image/\(shard1)/\(key1)_thumb.png")
        let file2 = bin.appendingPathComponent("Data/Image/\(shard2)/\(key2)_thumb.png")

        let attrs1 = try FileManager.default.attributesOfItem(atPath: file1.path)
        let attrs2 = try FileManager.default.attributesOfItem(atPath: file2.path)

        let inode1 = attrs1[.systemFileNumber] as? UInt64
        let inode2 = attrs2[.systemFileNumber] as? UInt64

        #expect(inode1 != nil)
        #expect(inode1 == inode2)
    }

    /// Inserting the same CGImage as a primary for two different audio URLs should produce
    /// two primary files that share an inode.
    @Test func primaryDeduplicatesViaHardlink() async throws {
        deleteBinOnExit = true
        let store = try ImageDataStore(inDirectory: bin)
        let image = try syntheticImage(width: 100, height: 100, utType: .jpeg)
        let url1 = fakeURL(index: 202)
        let url2 = fakeURL(index: 203)

        try await store.insert(.fullQuality, cgImage: image, for: url1)
        try await store.insert(.fullQuality, cgImage: image, for: url2)

        let key1 = url1.sha256
        let key2 = url2.sha256
        let shard1 = String(key1.prefix(2))
        let shard2 = String(key2.prefix(2))
        let file1 = bin.appendingPathComponent("Data/Image/\(shard1)/\(key1)_full.jpeg")
        let file2 = bin.appendingPathComponent("Data/Image/\(shard2)/\(key2)_full.jpeg")

        let attrs1 = try FileManager.default.attributesOfItem(atPath: file1.path)
        let attrs2 = try FileManager.default.attributesOfItem(atPath: file2.path)

        let inode1 = attrs1[.systemFileNumber] as? UInt64
        let inode2 = attrs2[.systemFileNumber] as? UInt64

        #expect(inode1 != nil)
        #expect(inode1 == inode2)
    }

    /// Distinct images inserted for different URLs must not share an inode.
    @Test func distinctImagesHaveDifferentInodes() async throws {
        deleteBinOnExit = true
        let store = try ImageDataStore(inDirectory: bin)
        let imageA = try syntheticImage(width: 100, height: 100)
        let imageB = try syntheticImage(width: 200, height: 200)
        let url1 = fakeURL(index: 204)
        let url2 = fakeURL(index: 205)

        try await store.insert(.thumbnail, cgImage: imageA, for: url1)
        try await store.insert(.thumbnail, cgImage: imageB, for: url2)

        let key1 = url1.sha256
        let key2 = url2.sha256
        let shard1 = String(key1.prefix(2))
        let shard2 = String(key2.prefix(2))
        let file1 = bin.appendingPathComponent("Data/Image/\(shard1)/\(key1)_thumb.png")
        let file2 = bin.appendingPathComponent("Data/Image/\(shard2)/\(key2)_thumb.png")

        let attrs1 = try FileManager.default.attributesOfItem(atPath: file1.path)
        let attrs2 = try FileManager.default.attributesOfItem(atPath: file2.path)

        let inode1 = attrs1[.systemFileNumber] as? UInt64
        let inode2 = attrs2[.systemFileNumber] as? UInt64

        #expect(inode1 != nil)
        #expect(inode2 != nil)
        #expect(inode1 != inode2)
    }
}
