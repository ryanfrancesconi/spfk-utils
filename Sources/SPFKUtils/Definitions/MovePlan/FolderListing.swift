// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKBase

/// The names in each folder a run touches, read once and compared by each volume's case rule, so
/// planning a run never stats a candidate name.
public struct FolderListing: Sendable {
    /// Every listed name as ``key(_:)`` spells it.
    private var keys: Set<String> = []

    /// Each listed folder's path, with whether its volume compares case.
    private var caseRules: [String: Bool] = [:]

    /// - Parameter folders: each folder's names, as a listing would give them.
    public init(folders: [URL: [String]], caseSensitive: Bool) {
        for (folder, names) in folders {
            add(folder, names: names, isCaseSensitive: caseSensitive)
        }
    }

    /// One listing of each folder.
    public static func reading(_ folders: some Sequence<URL>) -> FolderListing {
        var listing = FolderListing(folders: [:], caseSensitive: false)

        for folder in folders where listing.caseRules[Self.path(of: folder)] == nil {
            let names: [String]

            do {
                names = try FileManager.default.contentsOfDirectory(atPath: folder.path)
            } catch {
                Log.error("Couldn't list \(folder.lastPathComponent)", error)
                names = []
            }

            listing.add(folder, names: names, isCaseSensitive: BatchOutputClaims.volumeIsCaseSensitive(at: folder))
        }

        return listing
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
