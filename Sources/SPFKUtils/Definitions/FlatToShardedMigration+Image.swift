// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKBase

// MARK: - Image Factory

extension FlatToShardedMigration {
    /// Creates a migration for `ImageDataStore`'s legacy flat `Image/` directory.
    ///
    /// - Parameter cachesDirectory: the same `inDirectory` the store was initialized with.
    ///   Old flat location: `<cachesDirectory>/Image`. Target: `<cachesDirectory>/Data/Image`.
    public static func image(inCachesDirectory cachesDirectory: URL) -> Self {
        let oldFlatDirectory = cachesDirectory.appendingPathComponent("Image")
        let shardedDirectory = ShardedDirectory(
            rootURL: cachesDirectory.appendingPathComponent("Data/Image")
        )

        return Self(
            oldFlatDirectoryURL: oldFlatDirectory,
            keyExtractor: { file in
                let name = file.lastPathComponent
                if name.hasSuffix("_thumb.png") { return String(name.dropLast("_thumb.png".count)) }
                for ext in ["png", "jpeg", "jpg"] {
                    let suffix = "_full.\(ext)"
                    if name.hasSuffix(suffix) { return String(name.dropLast(suffix.count)) }
                }
                return nil
            },
            migrateEntry: { key in
                try migrateImageEntry(key: key, from: oldFlatDirectory, to: shardedDirectory)
            },
            deleteOldFiles: { key in
                let fm = FileManager.default
                try? fm.removeItem(at: oldFlatDirectory.appendingPathComponent("\(key)_thumb.png"))
                for ext in ["png", "jpeg", "jpg"] {
                    try? fm.removeItem(at: oldFlatDirectory.appendingPathComponent("\(key)_full.\(ext)"))
                }
            }
        )
    }
}

// MARK: - Image Migration Helpers

private func migrateImageEntry(
    key: String,
    from oldFlatDirectory: URL,
    to shardedDirectory: ShardedDirectory
) throws {
    let fm = FileManager.default
    var movedAny = false

    let oldThumb = oldFlatDirectory.appendingPathComponent("\(key)_thumb.png")
    if fm.fileExists(atPath: oldThumb.path) {
        try shardedDirectory.ensureShardDirectory(for: key)
        let newThumb = shardedDirectory.fileURL(for: key, suffix: "_thumb.png")
        if fm.fileExists(atPath: newThumb.path) {
            try fm.removeItem(at: oldThumb)
        } else {
            try fm.moveItem(at: oldThumb, to: newThumb)
        }
        movedAny = true
    }

    for ext in ["png", "jpeg", "jpg"] {
        let suffix = "_full.\(ext)"
        let oldPrimary = oldFlatDirectory.appendingPathComponent("\(key)\(suffix)")
        if fm.fileExists(atPath: oldPrimary.path) {
            try shardedDirectory.ensureShardDirectory(for: key)
            let newPrimary = shardedDirectory.fileURL(for: key, suffix: suffix)
            if fm.fileExists(atPath: newPrimary.path) {
                try fm.removeItem(at: oldPrimary)
            } else {
                try fm.moveItem(at: oldPrimary, to: newPrimary)
            }
            movedAny = true
        }
    }

    if !movedAny {
        Log.debug("Image migration: no files found for key \(key)")
    }
}
