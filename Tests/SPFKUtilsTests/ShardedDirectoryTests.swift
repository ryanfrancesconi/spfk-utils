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

    // MARK: - flatToShardedSweep

    @Test func sweepIsNoOpIfOldDirectoryMissing() throws {
        deleteBinOnExit = true
        let missing = bin.appendingPathComponent("does_not_exist")
        var called = false

        flatToShardedSweep(
            oldFlatDirectory: missing,
            keyExtractor: { _ in "key" },
            migrateEntry: { _ in called = true }
        )

        #expect(!called)
    }

    @Test func sweepCallsMigrateForEachUniqueKey() throws {
        deleteBinOnExit = true
        let flat = bin.appendingPathComponent("flat")
        try FileManager.default.createDirectory(at: flat, withIntermediateDirectories: true)

        // Two files with different keys
        try Data("a".utf8).write(to: flat.appendingPathComponent("key1.txt"))
        try Data("b".utf8).write(to: flat.appendingPathComponent("key2.txt"))

        var migrated = Set<String>()
        flatToShardedSweep(
            oldFlatDirectory: flat,
            keyExtractor: { file in
                let name = file.lastPathComponent
                guard name.hasSuffix(".txt") else { return nil }
                return String(name.dropLast(4))
            },
            migrateEntry: { key in
                migrated.insert(key)
                // Simulate: delete the file so the directory becomes empty
                try FileManager.default.removeItem(at: flat.appendingPathComponent("\(key).txt"))
            }
        )

        #expect(migrated == ["key1", "key2"])
    }

    @Test func sweepDeduplicatesKeyAcrossMultipleFiles() throws {
        deleteBinOnExit = true
        let flat = bin.appendingPathComponent("flat_dedup")
        try FileManager.default.createDirectory(at: flat, withIntermediateDirectories: true)

        // Two files with the same key, different suffixes
        try Data("a".utf8).write(to: flat.appendingPathComponent("key_thumb.png"))
        try Data("b".utf8).write(to: flat.appendingPathComponent("key_full.jpeg"))

        var callCount = 0
        flatToShardedSweep(
            oldFlatDirectory: flat,
            keyExtractor: { file in
                let name = file.lastPathComponent
                for suffix in ["_thumb.png", "_full.jpeg"] {
                    if name.hasSuffix(suffix) { return String(name.dropLast(suffix.count)) }
                }
                return nil
            },
            migrateEntry: { _ in
                callCount += 1
                // Remove both files
                try? FileManager.default.removeItem(at: flat.appendingPathComponent("key_thumb.png"))
                try? FileManager.default.removeItem(at: flat.appendingPathComponent("key_full.jpeg"))
            }
        )

        #expect(callCount == 1)
    }

    @Test func sweepSkipsFilesWithNoKey() throws {
        deleteBinOnExit = true
        let flat = bin.appendingPathComponent("flat_skip")
        try FileManager.default.createDirectory(at: flat, withIntermediateDirectories: true)

        try Data("x".utf8).write(to: flat.appendingPathComponent("unknown_format.xyz"))

        var called = false
        flatToShardedSweep(
            oldFlatDirectory: flat,
            keyExtractor: { _ in nil },
            migrateEntry: { _ in called = true }
        )

        #expect(!called)
    }

    @Test func sweepDeletesOldDirectoryWhenEmpty() throws {
        deleteBinOnExit = true
        let flat = bin.appendingPathComponent("flat_del")
        try FileManager.default.createDirectory(at: flat, withIntermediateDirectories: true)
        try Data("d".utf8).write(to: flat.appendingPathComponent("key.txt"))

        flatToShardedSweep(
            oldFlatDirectory: flat,
            keyExtractor: { file in
                file.pathExtension == "txt" ? file.deletingPathExtension().lastPathComponent : nil
            },
            migrateEntry: { key in
                try FileManager.default.removeItem(at: flat.appendingPathComponent("\(key).txt"))
            }
        )

        #expect(!FileManager.default.fileExists(atPath: flat.path))
    }

    @Test func sweepLeavesOldDirectoryIfEntriesRemain() throws {
        deleteBinOnExit = true
        let flat = bin.appendingPathComponent("flat_partial")
        try FileManager.default.createDirectory(at: flat, withIntermediateDirectories: true)
        try Data("a".utf8).write(to: flat.appendingPathComponent("key1.txt"))
        try Data("b".utf8).write(to: flat.appendingPathComponent("key2.txt"))

        // Only remove key1 — key2 "fails" (simulates a locked file)
        flatToShardedSweep(
            oldFlatDirectory: flat,
            keyExtractor: { file in
                file.pathExtension == "txt" ? file.deletingPathExtension().lastPathComponent : nil
            },
            migrateEntry: { key in
                if key == "key1" {
                    try FileManager.default.removeItem(at: flat.appendingPathComponent("\(key).txt"))
                } else {
                    throw NSError(domain: "test", code: 1, userInfo: nil)
                }
            }
        )

        // Directory still exists because key2 was not removed
        #expect(FileManager.default.fileExists(atPath: flat.path))
        #expect(FileManager.default.fileExists(atPath: flat.appendingPathComponent("key2.txt").path))
    }

    @Test func sweepDeletesDirectoryEvenWithStrayTempFiles() throws {
        deleteBinOnExit = true
        let flat = bin.appendingPathComponent("flat_strays")
        try FileManager.default.createDirectory(at: flat, withIntermediateDirectories: true)
        try Data("d".utf8).write(to: flat.appendingPathComponent("key.txt"))
        // Stray macOS atomic-write temp file
        try Data("t".utf8).write(to: flat.appendingPathComponent("key.txt.sb-2390a4f5-ih9WJn"))

        flatToShardedSweep(
            oldFlatDirectory: flat,
            keyExtractor: { file in
                file.pathExtension == "txt" ? file.deletingPathExtension().lastPathComponent : nil
            },
            migrateEntry: { key in
                try FileManager.default.removeItem(at: flat.appendingPathComponent("\(key).txt"))
            }
        )

        // Both the stray temp file and the directory must be gone
        #expect(!FileManager.default.fileExists(atPath: flat.path))
    }

    @Test func sweepIsResumable() throws {
        deleteBinOnExit = true
        let flat = bin.appendingPathComponent("flat_resume")
        try FileManager.default.createDirectory(at: flat, withIntermediateDirectories: true)
        try Data("a".utf8).write(to: flat.appendingPathComponent("key1.txt"))
        try Data("b".utf8).write(to: flat.appendingPathComponent("key2.txt"))

        var migratedFirstRun = Set<String>()

        // First sweep: fail on key2 (simulate interrupted sweep)
        flatToShardedSweep(
            oldFlatDirectory: flat,
            keyExtractor: { file in
                file.pathExtension == "txt" ? file.deletingPathExtension().lastPathComponent : nil
            },
            migrateEntry: { key in
                migratedFirstRun.insert(key)
                if key == "key2" { throw NSError(domain: "test", code: 1, userInfo: nil) }
                try FileManager.default.removeItem(at: flat.appendingPathComponent("\(key).txt"))
            }
        )

        #expect(FileManager.default.fileExists(atPath: flat.path)) // Not deleted yet
        #expect(!FileManager.default.fileExists(atPath: flat.appendingPathComponent("key1.txt").path))
        #expect(FileManager.default.fileExists(atPath: flat.appendingPathComponent("key2.txt").path))

        // Second sweep: key1 is gone, only key2 remains
        var migratedSecondRun = Set<String>()
        flatToShardedSweep(
            oldFlatDirectory: flat,
            keyExtractor: { file in
                file.pathExtension == "txt" ? file.deletingPathExtension().lastPathComponent : nil
            },
            migrateEntry: { key in
                migratedSecondRun.insert(key)
                try FileManager.default.removeItem(at: flat.appendingPathComponent("\(key).txt"))
            }
        )

        #expect(migratedSecondRun == ["key2"])
        #expect(!FileManager.default.fileExists(atPath: flat.path)) // Now deleted
    }
}
