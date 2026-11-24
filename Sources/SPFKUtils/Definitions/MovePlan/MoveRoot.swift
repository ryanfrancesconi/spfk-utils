// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKBase
import SPFKFileSystem

/// The folder a run renders its folders under, checked once when it is chosen.
public struct MoveRoot: Sendable, Hashable {
    public let url: URL

    /// The mount point of the root's volume. A file on another volume stays where it is.
    public let volume: URL?

    /// Whether the root's volume compares names by case. Every folder under the root, made or not
    /// yet made, is taken to share it.
    public let isCaseSensitive: Bool

    init(url: URL, volume: URL?, isCaseSensitive: Bool) {
        self.url = url.standardizedFileURL
        self.volume = volume
        self.isCaseSensitive = isCaseSensitive
    }
}

extension MoveRoot {
    /// Refuses a folder that is or is inside a package or a Photos library, or that can't be
    /// written, with a ``MoveRootError`` naming it; otherwise reads its volume and case rule.
    public init(validating url: URL) throws {
        let url = url.standardizedFileURL

        guard !url.isInsideOrIsPackage else { throw MoveRootError.insidePackage(url) }
        guard FileManager.default.isWritableFile(atPath: url.path) else { throw MoveRootError.notWritable(url) }

        let values: URLResourceValues

        do {
            values = try url.resourceValues(forKeys: [.volumeURLKey, .volumeSupportsCaseSensitiveNamesKey])
        } catch {
            Log.error("Couldn't read the volume of \(url.lastPathComponent)", error)
            throw MoveRootError.unreadable(url)
        }

        self.init(url: url, volume: values.volume, isCaseSensitive: values.volumeSupportsCaseSensitiveNames ?? false)
    }

    /// The deepest folder holding every file of `urls`.
    public static func commonAncestor(of urls: [URL]) -> URL {
        let folders = urls.map { $0.deletingLastPathComponent().standardizedFileURL.pathComponents }

        guard var common = folders.first else { return URL(fileURLWithPath: "/", isDirectory: true) }

        for components in folders.dropFirst() {
            common = Array(zip(common, components).prefix { $0 == $1 }.map(\.0))
        }

        return URL(fileURLWithPath: NSString.path(withComponents: common.isEmpty ? ["/"] : common), isDirectory: true)
    }

    /// The mount point of the volume holding `folder`, or nil when it can't be read.
    public static func volume(of folder: URL) -> URL? {
        do {
            return try folder.resourceValues(forKeys: [.volumeURLKey]).volume
        } catch {
            Log.error("Couldn't read the volume of \(folder.lastPathComponent)", error)
            return nil
        }
    }
}

extension URL {
    /// Whether this URL, or a folder above it, is a bundle or a Photos library.
    public var isInsideOrIsPackage: Bool {
        var candidate = standardizedFileURL

        while candidate.path != "/" {
            if candidate.isPackage { return true }
            candidate = candidate.deletingLastPathComponent()
        }

        return false
    }
}
