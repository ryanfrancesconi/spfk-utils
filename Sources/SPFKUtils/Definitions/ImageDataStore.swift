// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import CoreGraphics
import Foundation
import SPFKBase
import UniformTypeIdentifiers

// MARK: - ImageDataStore

public actor ImageDataStore {
    /// Sharded cache root: `<inDirectory>/Data/Image/<shard>/<key><suffix>`
    public nonisolated let directoryURL: URL
    nonisolated let shardedDirectory: ShardedDirectory

    /// Session-scoped content fingerprint caches: fingerprint → first-written urlKey.
    /// Subsequent inserts of identical images are hardlinked to the existing file instead of
    /// being re-encoded and re-written. Hardlinks share the same inode so `exists`, `fetch`,
    /// and `prune` all work transparently.
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

    private func entryKeys() -> [String] {
        shardedDirectory.entryKeys(suffix: Self.thumbSuffix)
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
            Log.debug("pruning orphaned image cache: \(key)")
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

        if let fp = cgImage.fingerprint, let existingKey = thumbnailFingerprintCache[fp] {
            let existingURL = thumbnailURL(for: existingKey)
            if FileManager.default.fileExists(atPath: existingURL.path) {
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

        if let fp = cgImage.fingerprint {
            thumbnailFingerprintCache[fp] = key
        }
    }

    private func insertPrimary(cgImage: CGImage, url: URL) throws {
        guard let utTypeString = cgImage.utType, let utType = UTType(utTypeString as String) else {
            throw NSError(description: "Unknown UTType in cgImage")
        }

        let key = url.sha256
        let ext = utType.preferredFilenameExtension ?? (utType == .png ? "png" : "jpeg")
        let destURL = primaryURL(for: key, ext: ext)

        if let existing = existingPrimaryURL(for: key), existing != destURL {
            try? FileManager.default.removeItem(at: existing)
        }

        if let fp = cgImage.fingerprint, let existingKey = primaryFingerprintCache[fp] {
            let existingURL = primaryURL(for: existingKey, ext: ext)
            if FileManager.default.fileExists(atPath: existingURL.path) {
                try shardedDirectory.ensureShardDirectory(for: key)
                try? FileManager.default.removeItem(at: destURL)
                try FileManager.default.linkItem(at: existingURL, to: destURL)
                return
            }
        }

        try shardedDirectory.ensureShardDirectory(for: key)
        try cgImage.export(utType: utType, to: destURL)

        if let fp = cgImage.fingerprint {
            primaryFingerprintCache[fp] = key
        }
    }
}
