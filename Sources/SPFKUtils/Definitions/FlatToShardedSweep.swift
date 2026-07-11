// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKBase

/// Sweeps a legacy flat cache directory, migrating each entry via `migrateEntry`,
/// then deletes the old directory once it is empty.
///
/// This is a one-time startup migration for stores transitioning from a flat directory to a sharded
/// layout. It is safe to interrupt: the old directory's presence is the resume marker. If a launch is
/// interrupted partway through, remaining entries are retried on the next launch.
///
/// - Parameters:
///   - oldFlatDirectory: The legacy flat directory. Returns immediately if it does not exist.
///   - keyExtractor: Extracts a cache key from a file URL in the flat directory. Return `nil` to skip
///     the file. If multiple files share a key (e.g. thumbnail + primary image), each file is still
///     passed to `keyExtractor`, but `migrateEntry` is called only once per unique key.
///   - migrateEntry: Called once per unique key found in the flat directory. Must move or migrate the
///     entry's file(s) to the new location and clean up old files. If it throws, the key is skipped
///     and retried on the next sweep.
public func flatToShardedSweep(
    oldFlatDirectory: URL,
    keyExtractor: (_ fileURL: URL) -> String?,
    migrateEntry: (_ key: String) throws -> Void
) {
    let fm = FileManager.default
    guard fm.fileExists(atPath: oldFlatDirectory.path) else { return }
    guard let files = try? fm.contentsOfDirectory(at: oldFlatDirectory, includingPropertiesForKeys: nil) else { return }

    var seen = Set<String>()
    for file in files {
        guard let key = keyExtractor(file) else { continue }
        guard seen.insert(key).inserted else { continue }
        do {
            try migrateEntry(key)
        } catch {
            Log.debug("flatToShardedSweep: skipping key \(key): \(error)")
        }
    }

    // Remove the old directory once all recognizable entries have been swept.
    // Any files the keyExtractor can't identify (stray .sb-* atomic-write temps, .DS_Store, etc.)
    // are safe to delete in a cache directory we own — they block directory removal otherwise.
    let remaining = (try? fm.contentsOfDirectory(at: oldFlatDirectory, includingPropertiesForKeys: nil)) ?? []
    let unprocessedKeys = remaining.compactMap { keyExtractor($0) }
    if unprocessedKeys.isEmpty {
        for file in remaining {
            try? fm.removeItem(at: file)
        }
        try? fm.removeItem(at: oldFlatDirectory)
    }
}
