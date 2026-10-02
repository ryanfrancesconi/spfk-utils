// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import CoreGraphics
import Foundation
import SPFKBase
import SPFKImage
import UniformTypeIdentifiers

// MARK: - ImageDataStore

public actor ImageDataStore {
    /// Sharded cache root: `<inDirectory>/Data/Image/<shard>/<key><suffix>`
    public nonisolated let directoryURL: URL
    nonisolated let shardedDirectory: ShardedDirectory

    /// Session-scoped content fingerprint caches: fingerprint → the key whose file holds it.
    /// Identical pixels inserted for two keys share one file through a hardlink. Rewriting a key
    /// drops its entries first, so it never changes what another key holds.
    private var thumbnailFingerprintCache: [Int: String] = [:]
    private var primaryFingerprintCache: [Int: String] = [:]

    /// File naming constants — implementation detail of the disk layout.
    static let thumbSuffix = "_thumb.png"
    static let fullSuffix = "_full"
    static let fullExtensions = ["png", "jpeg", "jpg"]

    public init(inDirectory: URL) throws {
        directoryURL = inDirectory.appendingPathComponent("Data/Image")
        shardedDirectory = ShardedDirectory(rootURL: directoryURL)
        try Self.ensureDirectory(at: directoryURL)
    }

    private static func ensureDirectory(at url: URL) throws {
        let fm = FileManager.default
        if !fm.fileExists(atPath: url.path) {
            try fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    // MARK: - Private Filename Helpers

    private func thumbnailURL(for key: String) -> URL {
        shardedDirectory.fileURL(for: key, suffix: Self.thumbSuffix)
    }

    private func primaryURL(for key: String, ext: String) -> URL {
        shardedDirectory.fileURL(for: key, suffix: "\(Self.fullSuffix).\(ext)")
    }

    /// Returns the existing primary image URL by probing each candidate extension.
    private func existingPrimaryURL(for key: String) -> URL? {
        let fm = FileManager.default
        for ext in Self.fullExtensions {
            let url = primaryURL(for: key, ext: ext)
            if fm.fileExists(atPath: url.path) { return url }
        }
        return nil
    }

    private func deleteFiles(for key: String) {
        let fm = FileManager.default
        try? fm.removeItem(at: thumbnailURL(for: key))
        for ext in Self.fullExtensions {
            try? fm.removeItem(at: primaryURL(for: key, ext: ext))
        }
    }

    /// Every key with a thumbnail, a primary, or both.
    private func entryKeys() -> [String] {
        let suffixes = [Self.thumbSuffix] + Self.fullExtensions.map { "\(Self.fullSuffix).\($0)" }
        let keys = suffixes.flatMap { shardedDirectory.entryKeys(suffix: $0) }
        return Array(Set(keys))
    }
}

// MARK: - Public

extension ImageDataStore {
    public func insert(_ type: CachedImageType, cgImage: CGImage, for url: URL) throws {
        switch type {
        case .thumbnail:
            try insertThumbnail(cgImage: cgImage, url: url)
        case .fullQuality:
            try insertPrimary(cgImage: cgImage, url: url)
        }
    }

    /// Returns the cached CGImage for the given type, or nil if not cached.
    public func fetch(_ type: CachedImageType, for url: URL) -> CGImage? {
        let key = url.sha256

        let fileURL: URL?
        switch type {
        case .thumbnail:
            let thumbURL = thumbnailURL(for: key)
            fileURL = FileManager.default.fileExists(atPath: thumbURL.path) ? thumbURL : nil
        case .fullQuality:
            fileURL = existingPrimaryURL(for: key)
        }

        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? CGImage.create(from: data)
    }

    /// When the cached image for `url` was written, or nil when nothing is cached.
    ///
    /// Entries are keyed by URL with no content fingerprint, so a file rewritten at the same path
    /// keeps serving what was cached for its previous contents. A caller exposed to that -- an
    /// in-place render, or a library the user edits in other apps -- compares this against the
    /// file's own modification date and discards the entry when the file is newer.
    public func cacheDate(_ type: CachedImageType, for url: URL) -> Date? {
        let key = url.sha256

        let fileURL: URL?
        switch type {
        case .thumbnail:
            let thumbURL = thumbnailURL(for: key)
            fileURL = FileManager.default.fileExists(atPath: thumbURL.path) ? thumbURL : nil
        case .fullQuality:
            fileURL = existingPrimaryURL(for: key)
        }

        guard let fileURL else { return nil }

        return try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    /// Returns true if a thumbnail exists for the URL (does not load it).
    public func exists(url: URL) -> Bool {
        FileManager.default.fileExists(atPath: thumbnailURL(for: url.sha256).path)
    }

    public func delete(url: URL) {
        deleteFiles(for: url.sha256)
    }

    public func deleteAll() {
        let fm = FileManager.default
        guard let shardDirs = try? fm.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.isDirectoryKey]
        ) else { return }

        for shardDir in shardDirs {
            guard (try? shardDir.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true else { continue }
            guard let files = try? fm.contentsOfDirectory(at: shardDir, includingPropertiesForKeys: nil) else { continue }
            for file in files {
                let name = file.lastPathComponent
                if name.hasSuffix(Self.thumbSuffix) ||
                    Self.fullExtensions.contains(where: { name.hasSuffix("\(Self.fullSuffix).\($0)") })
                {
                    try? fm.removeItem(at: file)
                }
            }
        }
    }

    public func count() -> Int {
        entryKeys().count
    }

    /// Moves every cached image for `oldURL` to `newURL`, for a file that moved without its content
    /// changing. When `newURL` already has entries they win, and `oldURL`'s are deleted.
    ///
    /// Each moved entry is stamped with the current date, since a caller compares an entry's date
    /// against its file's and the moved file may be newer than the entry. **Only call this for a
    /// file verified to hold the same content** — the stamp is what asserts it. Copied rather than
    /// renamed, so the stamp cannot reach another key sharing the entry through a hardlink.
    public func rekey(from oldURL: URL, to newURL: URL) throws {
        let oldKey = oldURL.sha256
        let newKey = newURL.sha256

        guard oldKey != newKey else { return }

        defer { deleteFiles(for: oldKey) }

        let fm = FileManager.default

        guard !fm.fileExists(atPath: thumbnailURL(for: newKey).path), existingPrimaryURL(for: newKey) == nil else {
            return
        }

        var moves: [(from: URL, to: URL)] = []

        let thumbnail = thumbnailURL(for: oldKey)
        if fm.fileExists(atPath: thumbnail.path) {
            moves.append((thumbnail, thumbnailURL(for: newKey)))
        }

        if let primary = existingPrimaryURL(for: oldKey) {
            moves.append((primary, primaryURL(for: newKey, ext: primary.pathExtension)))
        }

        guard moves.isNotEmpty else { return }

        try shardedDirectory.ensureShardDirectory(for: newKey)

        let now = Date()

        for move in moves {
            try fm.copyItem(at: move.from, to: move.to)
            try fm.setAttributes([.modificationDate: now], ofItemAtPath: move.to.path)
        }

        thumbnailFingerprintCache = thumbnailFingerprintCache.filter { $0.value != oldKey }
        primaryFingerprintCache = primaryFingerprintCache.filter { $0.value != oldKey }
    }

    @discardableResult
    public func prune(activeURLs: Set<URL>) -> Int {
        prune(activeKeys: Set(activeURLs.map(\.sha256)))
    }

    @discardableResult
    public func prune(activeKeys: Set<String>) -> Int {
        // An empty set means the caller could not enumerate what is live, not that nothing is.
        // Pruning against it deletes every entry here.
        guard activeKeys.isNotEmpty else { return 0 }

        var removedCount = 0

        for key in entryKeys() where !activeKeys.contains(key) {
            deleteFiles(for: key)
            removedCount += 1
        }

        return removedCount
    }

    /// No-op — each insert writes immediately.
    /// Kept for API symmetry with other stores.
    public func save() {}
}

// MARK: - Private Insert Helpers

extension ImageDataStore {
    private func insertThumbnail(cgImage: CGImage, url: URL) throws {
        let key = url.sha256
        let destURL = thumbnailURL(for: key)

        let fingerprint = cgImage.fingerprint
        let existingKey = fingerprint.flatMap { thumbnailFingerprintCache[$0] }

        if existingKey == key, FileManager.default.fileExists(atPath: destURL.path) {
            return
        }

        thumbnailFingerprintCache = thumbnailFingerprintCache.filter { $0.value != key }

        if let existingKey {
            let existingURL = thumbnailURL(for: existingKey)
            if existingURL != destURL, FileManager.default.fileExists(atPath: existingURL.path) {
                try shardedDirectory.ensureShardDirectory(for: key)
                try? FileManager.default.removeItem(at: destURL)
                try FileManager.default.linkItem(at: existingURL, to: destURL)
                return
            }
        }

        guard let data = cgImage.pngRepresentation else {
            throw NSError(description: "Failed to create PNG thumbnail for \(url.lastPathComponent)")
        }

        try shardedDirectory.ensureShardDirectory(for: key)
        try data.write(to: destURL, options: .atomic)

        if let fingerprint {
            thumbnailFingerprintCache[fingerprint] = key
        }
    }

    private func insertPrimary(cgImage: CGImage, url: URL) throws {
        guard let utTypeString = cgImage.utType, let utType = UTType(utTypeString as String) else {
            throw NSError(description: "Unknown UTType in cgImage")
        }

        // Primaries are stored as PNG or JPEG only, the extensions every lookup probes.
        let storedType: UTType = utType == .jpeg ? .jpeg : .png
        let key = url.sha256
        let ext = storedType.preferredFilenameExtension ?? (storedType == .png ? "png" : "jpeg")
        let destURL = primaryURL(for: key, ext: ext)

        if let existing = existingPrimaryURL(for: key), existing != destURL {
            try? FileManager.default.removeItem(at: existing)
        }

        let fingerprint = cgImage.fingerprint
        let existingKey = fingerprint.flatMap { primaryFingerprintCache[$0] }

        if existingKey == key, FileManager.default.fileExists(atPath: destURL.path) {
            return
        }

        primaryFingerprintCache = primaryFingerprintCache.filter { $0.value != key }

        if let existingKey {
            let existingURL = primaryURL(for: existingKey, ext: ext)
            if existingURL != destURL, FileManager.default.fileExists(atPath: existingURL.path) {
                try shardedDirectory.ensureShardDirectory(for: key)
                try? FileManager.default.removeItem(at: destURL)
                try FileManager.default.linkItem(at: existingURL, to: destURL)
                return
            }
        }

        try shardedDirectory.ensureShardDirectory(for: key)
        try cgImage.export(utType: storedType, to: destURL)

        if let fingerprint {
            primaryFingerprintCache[fingerprint] = key
        }
    }
}
