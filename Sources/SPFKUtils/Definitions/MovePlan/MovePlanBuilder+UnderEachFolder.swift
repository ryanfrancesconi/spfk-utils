// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)

import Foundation
import SPFKBase

extension MovePlanBuilder {
    /// The folder `levels` are built under for a file in the folder at `path`: `path` less the
    /// longest leading run of `levels` it already ends in, compared by the folder's case rule.
    public static func baseFolder(path: String, levels: [String], isCaseSensitive: Bool) -> String {
        let components = path.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
        let key = { FolderListing.folderKey(path: $0, isCaseSensitive: isCaseSensitive) }

        for count in stride(from: min(levels.count, components.count), to: 0, by: -1) {
            let tail = components.suffix(count).map(key)
            guard tail == levels.prefix(count).map(key) else { continue }
            return "/" + components.dropLast(count).joined(separator: "/")
        }

        return path
    }
}

extension MovePlanBuilder.Pass {
    /// Each unit's folder under ``FolderPlacement/underEachFolder(_:)``: its lead's folder, less a
    /// leading run of the levels it already ends in, plus the levels. Matched by the lead's case rule.
    mutating func destinations(of units: [MovePlanBuilder.Unit], underEachFolder folderTemplate: NameTemplate) -> [MovePlanBuilder.Destination] {
        let prepared = builder.prepared
        var spelling: [String: (folder: URL, path: String)] = [:]

        func spellingKey(_ path: String, _ isCaseSensitive: Bool) -> String {
            (isCaseSensitive ? "1" : "0") + FolderListing.folderKey(path: path, isCaseSensitive: isCaseSensitive)
        }

        for (path, folder) in builder.sourceFolders {
            spelling[spellingKey(path, listing.isCaseSensitive(folderPath: path))] = (folder, path)
        }

        var folders: [(folder: URL, path: String)] = []
        var unlisted: [Bool: [String: String]] = [:]
        folders.reserveCapacity(units.count)

        for (offset, unit) in units.enumerated() {
            let lead = prepared[unit[0]]
            let context = NameTemplate.RenderContext(index: offset + 1, count: units.count, collection: collection)
            let levels = folderTemplate.renderLevels(values: lead.input.values, context: context)
            let base = MovePlanBuilder.baseFolder(path: lead.folderPath, levels: levels, isCaseSensitive: lead.isCaseSensitive)
            let path = levels.reduce(base) { $0.hasSuffix("/") ? $0 + $1 : $0 + "/" + $1 }
            let key = spellingKey(path, lead.isCaseSensitive)

            if let known = spelling[key] {
                folders.append(known)
                continue
            }

            let folder = (folder: URL(fileURLWithPath: path, isDirectory: true), path: path)
            spelling[key] = folder
            folders.append(folder)

            if !listing.isListed(folderPath: path) {
                unlisted[lead.isCaseSensitive, default: [:]][path] = base
            }
        }

        for (isCaseSensitive, bases) in unlisted {
            var paths: Set<String> = []

            for (path, base) in bases {
                paths.formUnion(Self.withAncestors([path], below: base))
            }

            listing.list(paths.map { URL(fileURLWithPath: $0, isDirectory: true) }, isCaseSensitive: isCaseSensitive)
        }

        return folders.map {
            MovePlanBuilder.Destination(folder: $0.folder, path: $0.path, isCaseSensitive: listing.isCaseSensitive(folderPath: $0.path))
        }
    }
}

#endif
