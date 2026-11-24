// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKBase

/// The names in each folder a run touches, read once and compared by each volume's case rule, so
/// planning a run never stats a candidate name.
public struct FolderListing: Sendable {
    /// One folder's names, or nil when the folder does not exist.
    public typealias Reader = @Sendable (URL) -> [String]?

    /// Every listed name as ``key(_:)`` spells it.
    private var keys: Set<String> = []

    /// Each listed folder's path, with whether its volume compares case.
    private var caseRules: [String: Bool] = [:]

    private let reader: Reader

    /// - Parameters:
    ///   - folders: each folder's names, as a listing would give them.
    ///   - reader: reads a folder ``list(_:isCaseSensitive:)`` is asked for. By default a folder not
    ///     in `folders` holds nothing.
    public init(folders: [URL: [String]], caseSensitive: Bool, reader: @escaping Reader = { _ in nil }) {
        self.reader = reader

        for (folder, names) in folders {
            add(folder, names: names, isCaseSensitive: caseSensitive)
        }
    }

    /// One listing of each folder, read from the disk, as is any folder listed later.
    public static func reading(_ folders: some Sequence<URL>) -> FolderListing {
        var listing = FolderListing(folders: [:], caseSensitive: false, reader: Self.readDisk)

        for folder in folders where listing.caseRules[Self.path(of: folder)] == nil {
            listing.add(folder, names: Self.readDisk(folder) ?? [], isCaseSensitive: BatchOutputClaims.volumeIsCaseSensitive(at: folder))
        }

        return listing
    }

    /// Lists each of `folders` not listed yet, all under `isCaseSensitive`. A folder whose parent is
    /// listed without it does not exist and is not read.
    public mutating func list(_ folders: some Sequence<URL>, isCaseSensitive: Bool) {
        let paths = Set(folders.map { Self.path(of: $0) }).filter { caseRules[$0] == nil }

        // Parents first, so a missing parent answers for its children.
        for path in paths.sorted(by: { $0.utf8.count < $1.utf8.count }) where caseRules[path] == nil {
            let folder = URL(fileURLWithPath: path, isDirectory: true)
            let parent = Self.path(of: folder.deletingLastPathComponent())

            let names: [String]? = if caseRules[parent] != nil, !holds(key: key(folder)) {
                nil
            } else {
                reader(folder)
            }

            add(folder, names: names ?? [], isCaseSensitive: isCaseSensitive)
        }
    }

    private static let readDisk: Reader = { folder in
        do {
            return try FileManager.default.contentsOfDirectory(atPath: folder.path)
        } catch CocoaError.fileReadNoSuchFile {
            return nil
        } catch {
            Log.error("Couldn't list \(folder.lastPathComponent)", error)
            return []
        }
    }

    /// Whether the listing holds a file at `url`. A folder never listed holds nothing.
    public func contains(_ url: URL) -> Bool {
        keys.contains(key(url))
    }

    /// A folder never listed counts as case-insensitive, which can only number a name that needed none.
    public func isCaseSensitive(_ folder: URL) -> Bool {
        isCaseSensitive(folderPath: Self.path(of: folder))
    }

    func isCaseSensitive(folderPath: String) -> Bool {
        caseRules[folderPath] ?? false
    }

    /// Whether the listing holds `key`, spelled as ``key(_:)`` spells it.
    func holds(key: String) -> Bool {
        keys.contains(key)
    }

    /// `url` as its folder's case rule compares it.
    func key(_ url: URL) -> String {
        let folderPath = Self.path(of: url.deletingLastPathComponent())
        return Self.key(name: url.lastPathComponent, folderPath: folderPath, isCaseSensitive: isCaseSensitive(folderPath: folderPath))
    }

    private mutating func add(_ folder: URL, names: [String], isCaseSensitive: Bool) {
        let path = Self.path(of: folder)
        caseRules[path] = isCaseSensitive
        keys.formUnion(names.map { Self.key(name: $0, folderPath: path, isCaseSensitive: isCaseSensitive) })
    }

    func isListed(folderPath: String) -> Bool {
        caseRules[folderPath] != nil
    }

    /// A folder's path as folders compare under `isCaseSensitive`.
    static func folderKey(path: String, isCaseSensitive: Bool) -> String {
        let normalized = path.utf8.allSatisfy { $0 < 0x80 } ? path : path.decomposedStringWithCanonicalMapping
        return isCaseSensitive ? normalized : normalized.lowercased()
    }

    static func path(of folder: URL) -> String {
        folder.standardizedFileURL.path
    }

    /// `name` in the folder at `folderPath`, normalized and, on a case-insensitive volume, case-folded.
    static func key(name: String, folderPath: String, isCaseSensitive: Bool) -> String {
        // ASCII has no decomposition, so it skips the bridged normalization.
        let normalized = name.utf8.allSatisfy { $0 < 0x80 } ? name : name.decomposedStringWithCanonicalMapping
        return folderPath + "/" + (isCaseSensitive ? normalized : normalized.lowercased())
    }
}
