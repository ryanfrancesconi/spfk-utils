// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKBase

/// The names in each folder a run touches, read once and compared by each volume's case rule, so
/// planning a run never stats a candidate name.
public struct FolderListing: Sendable {
    private struct Folder: Sendable {
        var keys: Set<String>
        var isCaseSensitive: Bool
    }

    private var folders: [String: Folder] = [:]

    /// - Parameter folders: each folder's names, as a listing would give them.
    public init(folders: [URL: [String]], caseSensitive: Bool) {
        for (folder, names) in folders {
            add(folder, names: names, isCaseSensitive: caseSensitive)
        }
    }

    /// One listing of each folder.
    public static func reading(_ folders: some Sequence<URL>) -> FolderListing {
        var listing = FolderListing(folders: [:], caseSensitive: false)

        for folder in folders where listing.folders[Self.path(of: folder)] == nil {
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
        guard let folder = folders[Self.path(of: url.deletingLastPathComponent())] else { return false }
        return folder.keys.contains(Self.key(url.lastPathComponent, isCaseSensitive: folder.isCaseSensitive))
    }

    /// A folder never listed counts as case-insensitive, which can only number a name that needed none.
    public func isCaseSensitive(_ folder: URL) -> Bool {
        folders[Self.path(of: folder)]?.isCaseSensitive ?? false
    }

    /// `url` as its folder's case rule compares it.
    func key(_ url: URL) -> String {
        let folder = url.deletingLastPathComponent()
        return Self.path(of: folder) + "/" + Self.key(url.lastPathComponent, isCaseSensitive: isCaseSensitive(folder))
    }

    private mutating func add(_ folder: URL, names: [String], isCaseSensitive: Bool) {
        folders[Self.path(of: folder)] = Folder(
            keys: Set(names.map { Self.key($0, isCaseSensitive: isCaseSensitive) }),
            isCaseSensitive: isCaseSensitive
        )
    }

    private static func path(of folder: URL) -> String {
        folder.standardizedFileURL.path
    }

    private static func key(_ name: String, isCaseSensitive: Bool) -> String {
        let normalized = name.decomposedStringWithCanonicalMapping
        return isCaseSensitive ? normalized : normalized.lowercased()
    }
}
