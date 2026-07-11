// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// Manages a sharded file directory using a 2-hex-char prefix scheme (256 shards).
///
/// Files are stored as `<root>/<key[0..<2]>/<key><suffix>`, mirroring the layout
/// used by `BookmarkDataStore`. This keeps individual directory sizes manageable at
/// large library scales where flat directories cause expensive enumeration costs.
public struct ShardedDirectory: Sendable {
    public let rootURL: URL

    public init(rootURL: URL) {
        self.rootURL = rootURL
    }

    /// Returns the shard subdirectory URL for the given key.
    public func shardURL(for key: String) -> URL {
        rootURL.appendingPathComponent(String(key.prefix(2)))
    }

    /// Returns the file URL for a key with the given filename suffix.
    ///
    /// The suffix should include any separator (e.g. `"_thumb.png"` or `".wfcache"`).
    public func fileURL(for key: String, suffix: String) -> URL {
        shardURL(for: key).appendingPathComponent("\(key)\(suffix)")
    }

    /// Creates the shard subdirectory for the given key if it does not already exist.
    public func ensureShardDirectory(for key: String) throws {
        let shard = shardURL(for: key)
        let fm = FileManager.default
        if !fm.fileExists(atPath: shard.path) {
            try fm.createDirectory(at: shard, withIntermediateDirectories: true)
        }
    }

    /// Enumerates all shard subdirectories and returns keys extracted from filenames
    /// that end with the given suffix.
    ///
    /// Non-directory entries at the root level are skipped.
    public func entryKeys(suffix: String) -> [String] {
        let fm = FileManager.default
        guard let shardDirs = try? fm.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey]
        ) else { return [] }

        var keys: [String] = []
        for shardDir in shardDirs {
            guard (try? shardDir.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true else { continue }
            guard let files = try? fm.contentsOfDirectory(at: shardDir, includingPropertiesForKeys: nil) else { continue }
            for file in files {
                let name = file.lastPathComponent
                guard name.hasSuffix(suffix) else { continue }
                keys.append(String(name.dropLast(suffix.count)))
            }
        }
        return keys
    }
}
