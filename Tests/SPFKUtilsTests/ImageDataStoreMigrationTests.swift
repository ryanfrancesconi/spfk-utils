// Copyright Ryan Francesconi. All Rights Reserved.

import CoreGraphics
import Foundation
import SPFKBase
import SPFKTesting
import Testing
import UniformTypeIdentifiers

@testable import SPFKUtils

@Suite(.tags(.file))
final class ImageDataStoreMigrationTests: BinTestCase {
    private func syntheticJPEG(width: Int = 64, height: Int = 64) throws -> CGImage {
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(red: 0, green: 0.5, blue: 1, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let raw = context.makeImage()!
        let data = try raw.dataRepresentation(utType: .jpeg)
        return try CGImage.create(from: data)
    }

    private func fakeURL(index: Int) -> URL {
        URL(string: "file:///fake/audio/migrate_\(index).mp3")!
    }

    private func populateLegacyFlatDirectory(count: Int, flatDir: URL) throws -> [URL] {
        try FileManager.default.createDirectory(at: flatDir, withIntermediateDirectories: true)
        var urls: [URL] = []
        for i in 0 ..< count {
            let url = fakeURL(index: i + 1000)
            let key = url.sha256
            let image = try syntheticJPEG()
            try image.pngRepresentation!.write(to: flatDir.appendingPathComponent("\(key)_thumb.png"))
            try image.dataRepresentation(utType: .jpeg).write(to: flatDir.appendingPathComponent("\(key)_full.jpeg"))
            urls.append(url)
        }
        return urls
    }

    // MARK: - Tests

    @Test func sweepMigratesEntriesToShardedLocation() async throws {
        deleteBinOnExit = true
        let migration = FlatToShardedMigration.image(inCachesDirectory: bin)
        let store = try ImageDataStore(inDirectory: bin)
        let urls = try populateLegacyFlatDirectory(count: 5, flatDir: migration.oldFlatDirectoryURL)

        await migration.start()?.value

        for url in urls {
            #expect(await store.exists(url: url), "Entry for \(url.lastPathComponent) should exist after sweep")
            #expect(await store.fetch(.thumbnail, for: url) != nil)
            #expect(await store.fetch(.fullQuality, for: url) != nil)
        }
        #expect(!FileManager.default.fileExists(atPath: migration.oldFlatDirectoryURL.path))
    }

    @Test func fetchDoesNotConsultOldFlatDirectory() async throws {
        deleteBinOnExit = true
        let migration = FlatToShardedMigration.image(inCachesDirectory: bin)
        let store = try ImageDataStore(inDirectory: bin)

        let url = fakeURL(index: 9000)
        let key = url.sha256
        try FileManager.default.createDirectory(at: migration.oldFlatDirectoryURL, withIntermediateDirectories: true)
        let image = try syntheticJPEG()
        try image.pngRepresentation!.write(to: migration.oldFlatDirectoryURL.appendingPathComponent("\(key)_thumb.png"))
        // Do NOT start sweep — fetch must only look at sharded location

        let result = await store.fetch(.thumbnail, for: url)
        #expect(result == nil, "fetch must not fall back to the old flat directory")
    }

    @Test func sweepPreservesHardlinks() async throws {
        deleteBinOnExit = true
        let migration = FlatToShardedMigration.image(inCachesDirectory: bin)
        let store = try ImageDataStore(inDirectory: bin)

        let url1 = fakeURL(index: 2001)
        let url2 = fakeURL(index: 2002)
        let key1 = url1.sha256
        let key2 = url2.sha256

        try FileManager.default.createDirectory(at: migration.oldFlatDirectoryURL, withIntermediateDirectories: true)
        let image = try syntheticJPEG()
        let path1 = migration.oldFlatDirectoryURL.appendingPathComponent("\(key1)_thumb.png")
        try image.pngRepresentation!.write(to: path1)
        let path2 = migration.oldFlatDirectoryURL.appendingPathComponent("\(key2)_thumb.png")
        try FileManager.default.linkItem(at: path1, to: path2)

        let inode1Before = try FileManager.default.attributesOfItem(atPath: path1.path)[.systemFileNumber] as? UInt64
        let inode2Before = try FileManager.default.attributesOfItem(atPath: path2.path)[.systemFileNumber] as? UInt64
        #expect(inode1Before == inode2Before)

        await migration.start()?.value

        let shard1 = String(key1.prefix(2))
        let shard2 = String(key2.prefix(2))
        let newPath1 = store.directoryURL.appendingPathComponent("\(shard1)/\(key1)_thumb.png")
        let newPath2 = store.directoryURL.appendingPathComponent("\(shard2)/\(key2)_thumb.png")

        let inode1After = try FileManager.default.attributesOfItem(atPath: newPath1.path)[.systemFileNumber] as? UInt64
        let inode2After = try FileManager.default.attributesOfItem(atPath: newPath2.path)[.systemFileNumber] as? UInt64
        #expect(inode1After == inode2After, "Hardlinks must be preserved through moveItem")
    }

    @Test func sweepDeletesOldDirectoryWhenComplete() async throws {
        deleteBinOnExit = true
        let migration = FlatToShardedMigration.image(inCachesDirectory: bin)
        _ = try ImageDataStore(inDirectory: bin)
        _ = try populateLegacyFlatDirectory(count: 3, flatDir: migration.oldFlatDirectoryURL)

        #expect(FileManager.default.fileExists(atPath: migration.oldFlatDirectoryURL.path))
        await migration.start()?.value

        #expect(!FileManager.default.fileExists(atPath: migration.oldFlatDirectoryURL.path))
    }

    @Test func oldFlatKeysIncludesEntriesBeforeSweep() async throws {
        deleteBinOnExit = true
        let migration = FlatToShardedMigration.image(inCachesDirectory: bin)
        let store = try ImageDataStore(inDirectory: bin)
        let flatURLs = try populateLegacyFlatDirectory(count: 4, flatDir: migration.oldFlatDirectoryURL)

        let freshURL = fakeURL(index: 9999)
        let image = try syntheticJPEG()
        try await store.insert(.thumbnail, cgImage: image, for: freshURL)

        let shardedCount = await store.count()
        let flatCount = migration.oldFlatKeys().count
        #expect(shardedCount + flatCount == flatURLs.count + 1)
    }

    @Test func pruneOldFlatRemovesOrphanedEntries() async throws {
        deleteBinOnExit = true
        let migration = FlatToShardedMigration.image(inCachesDirectory: bin)
        let store = try ImageDataStore(inDirectory: bin)
        let flatURLs = try populateLegacyFlatDirectory(count: 3, flatDir: migration.oldFlatDirectoryURL)

        let keepURL = fakeURL(index: 8888)
        let image = try syntheticJPEG()
        try await store.insert(.thumbnail, cgImage: image, for: keepURL)

        let activeKeys = Set([keepURL.sha256])
        let removed = migration.pruneOldFlat(retaining: activeKeys)
        #expect(removed == flatURLs.count)
        #expect(migration.oldFlatKeys().isEmpty)
    }
}
