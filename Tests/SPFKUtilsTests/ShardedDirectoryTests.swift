// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import SPFKBase
import SPFKTesting
import SPFKUtils
import Testing

@Suite(.tags(.file))
final class ShardedDirectoryTests: BinTestCase {
    private func makeDirectory() throws -> URL {
        let url = bin.appendingPathComponent("shards")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    // MARK: - ShardedDirectory

    @Test func fileURLUsesShardPrefix() throws {
        deleteBinOnExit = true
        let dir = try makeDirectory()
        let sd = ShardedDirectory(rootURL: dir)

        let key = "abcdef0123456789"
        let url = sd.fileURL(for: key, suffix: ".wfcache")
        let expected = dir
            .appendingPathComponent("ab")
            .appendingPathComponent("\(key).wfcache")

        #expect(url == expected)
    }

    @Test func ensureShardDirectoryCreatesSubdirectory() throws {
        deleteBinOnExit = true
        let dir = try makeDirectory()
        let sd = ShardedDirectory(rootURL: dir)
        let key = "ff0011223344"

        try sd.ensureShardDirectory(for: key)

        let shardDir = dir.appendingPathComponent("ff")
        #expect(FileManager.default.fileExists(atPath: shardDir.path))
    }

    @Test func ensureShardDirectoryIsIdempotent() throws {
        deleteBinOnExit = true
        let dir = try makeDirectory()
        let sd = ShardedDirectory(rootURL: dir)
        let key = "aa0011"

        try sd.ensureShardDirectory(for: key)
        // Calling again must not throw
        try sd.ensureShardDirectory(for: key)

        #expect(FileManager.default.fileExists(atPath: dir.appendingPathComponent("aa").path))
    }

    @Test func entryKeysReturnsEmptyForNewDirectory() throws {
        deleteBinOnExit = true
        let dir = try makeDirectory()
        let sd = ShardedDirectory(rootURL: dir)

        #expect(sd.entryKeys(suffix: ".wfcache").isEmpty)
    }

    @Test func entryKeysEnumeratesAllShards() throws {
        deleteBinOnExit = true
        let dir = try makeDirectory()
        let sd = ShardedDirectory(rootURL: dir)

        let keys = [
            "ab" + String(repeating: "0", count: 14),
            "ab" + String(repeating: "1", count: 14),
            "cd" + String(repeating: "2", count: 14),
        ]

        for key in keys {
            try sd.ensureShardDirectory(for: key)
            let fileURL = sd.fileURL(for: key, suffix: ".wfcache")
            try Data("data".utf8).write(to: fileURL)
        }

        let found = Set(sd.entryKeys(suffix: ".wfcache"))
        #expect(found == Set(keys))
    }

    @Test func entryKeysIgnoresFilesWithWrongSuffix() throws {
        deleteBinOnExit = true
        let dir = try makeDirectory()
        let sd = ShardedDirectory(rootURL: dir)

        let key = "ab" + String(repeating: "0", count: 14)
        try sd.ensureShardDirectory(for: key)

        // Write a .json file — should not appear when looking for .wfcache
        let jsonURL = sd.fileURL(for: key, suffix: ".json")
        try Data("{}".utf8).write(to: jsonURL)

        #expect(sd.entryKeys(suffix: ".wfcache").isEmpty)
        #expect(sd.entryKeys(suffix: ".json") == [key])
    }

    @Test func entryKeysIgnoresNonDirectoryEntriesAtRoot() throws {
        deleteBinOnExit = true
        let dir = try makeDirectory()
        let sd = ShardedDirectory(rootURL: dir)

        // Write a stray file at root level
        let strayFile = dir.appendingPathComponent("stray.wfcache")
        try Data("stray".utf8).write(to: strayFile)

        #expect(sd.entryKeys(suffix: ".wfcache").isEmpty)
    }
}
