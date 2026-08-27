// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// Manages migration of a legacy flat cache directory to a sharded layout.
///
/// Owns the knowledge of where the old directory was, how to enumerate and identify entries,
/// how to migrate each entry, and how to prune orphaned entries during the migration window.
/// The store itself has no knowledge of any prior location.
public struct FlatToShardedMigration: Sendable {
    public let oldFlatDirectoryURL: URL
    private let keyExtractor: @Sendable (URL) -> String?
    private let migrateEntry: @Sendable (String) throws -> Void
    private let deleteOldFiles: @Sendable (String) -> Void

    public init(
        oldFlatDirectoryURL: URL,
        keyExtractor: @Sendable @escaping (URL) -> String?,
        migrateEntry: @Sendable @escaping (String) throws -> Void,
        deleteOldFiles: @Sendable @escaping (String) -> Void
    ) {
        self.oldFlatDirectoryURL = oldFlatDirectoryURL
        self.keyExtractor = keyExtractor
        self.migrateEntry = migrateEntry
        self.deleteOldFiles = deleteOldFiles
    }

    public var isNeeded: Bool {
        FileManager.default.fileExists(atPath: oldFlatDirectoryURL.path)
    }

    /// Returns the SHA256 keys of all entries still present in the old flat directory.
    public func oldFlatKeys() -> Set<String> {
        guard isNeeded else { return [] }
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: oldFlatDirectoryURL,
            includingPropertiesForKeys: nil
        ) else { return [] }
        return Set(files.compactMap { keyExtractor($0) })
    }

    /// Removes entries from the old flat directory whose keys are not in `activeKeys`.
    /// Call from `pruneCaches()` during the migration window. No-op once migration is complete.
    /// - Returns: number of orphaned entries deleted
    @discardableResult
    public func pruneOldFlat(retaining activeKeys: Set<String>) -> Int {
        let orphaned = oldFlatKeys().subtracting(activeKeys)
        for key in orphaned {
            deleteOldFiles(key)
        }
        return orphaned.count
    }

    /// Starts a background sweep that migrates all entries from the old flat directory to the
    /// sharded location. No-op if the old directory does not exist. Resumable across launches.
    ///
    /// Returns the underlying `Task` so a caller that needs to know when the sweep actually
    /// finishes (tests, primarily — production fire-and-forget callers can ignore the
    /// `@discardableResult` return) can `await task?.value` instead of guessing a sleep
    /// duration, which is inherently racy under heavier system load (e.g. running as part of
    /// a large test batch rather than in isolation).
    ///
    /// Not `.background`: a process's first task at that priority waits on a background-QoS
    /// worker thread being spawned, measured at 2.7-48.6s for an empty closure.
    @discardableResult
    public func start() -> Task<Void, Never>? {
        guard isNeeded else { return nil }
        let url = oldFlatDirectoryURL
        let extract = keyExtractor
        let migrate = migrateEntry
        return Task.detached(priority: .utility) {
            flatToShardedSweep(oldFlatDirectory: url, keyExtractor: extract, migrateEntry: migrate)
        }
    }
}
