// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)

import Foundation
import SPFKBase

extension MovePlanBuilder {
    /// The folder a unit is named into.
    struct Destination {
        let folder: URL

        /// As ``FolderListing`` spells it, and the same for every unit placed in this folder.
        let path: String

        let isCaseSensitive: Bool
    }
}

extension MovePlanBuilder.Pass {
    /// Each unit's folder. Each rendered level matching one already known by the root's case rule, a
    /// source folder, an earlier unit's or one on disk, takes that spelling, and folders not listed
    /// yet are read.
    mutating func destinations(of units: [MovePlanBuilder.Unit]) -> [MovePlanBuilder.Destination] {
        let prepared = builder.prepared

        if case let .underEachFolder(folderTemplate) = placement {
            return destinations(of: units, underEachFolder: folderTemplate)
        }

        guard case let .template(folderTemplate, root) = placement else {
            return units.map {
                let lead = prepared[$0[0]]
                return MovePlanBuilder.Destination(folder: lead.folder, path: lead.folderPath, isCaseSensitive: lead.isCaseSensitive)
            }
        }

        let rule = root.isCaseSensitive
        let rootPath = FolderListing.path(of: root.url)
        var spelling = FolderSpelling(sourceFolders: builder.sourceFolders) { _ in rule }
        var folders: [(folder: URL, path: String)] = []
        var unlisted: Set<String> = []
        folders.reserveCapacity(units.count)

        for (offset, unit) in units.enumerated() {
            let context = NameTemplate.RenderContext(index: offset + 1, count: units.count, collection: collection)
            let levels = folderTemplate.renderLevels(values: prepared[unit[0]].input.values, context: context)
            let folder = spelling.folder(levels, under: rootPath, isCaseSensitive: rule, listing: &listing)
            folders.append(folder)

            if !listing.isListed(folderPath: folder.path) {
                unlisted.insert(folder.path)
            }
        }

        if unlisted.isNotEmpty {
            listing.list(Self.withAncestors(unlisted, below: rootPath).map { URL(fileURLWithPath: $0, isDirectory: true) }, isCaseSensitive: rule)
        }

        return folders.map {
            MovePlanBuilder.Destination(folder: $0.folder, path: $0.path, isCaseSensitive: listing.isCaseSensitive(folderPath: $0.path))
        }
    }

    /// The spelling each folder a pass has met takes, keyed by its path folded by its case rule.
    struct FolderSpelling {
        private var known: [String: (folder: URL, path: String)] = [:]

        /// Seeded with each source folder and every folder above it, as they are spelled.
        init(sourceFolders: [String: URL], isCaseSensitive: (String) -> Bool) {
            for (path, folder) in sourceFolders {
                let rule = isCaseSensitive(path)
                known[Self.key(path, rule)] = (folder, path)

                var ancestor = (path as NSString).deletingLastPathComponent

                while ancestor != "/", known[Self.key(ancestor, rule)] == nil {
                    known[Self.key(ancestor, rule)] = (URL(fileURLWithPath: ancestor, isDirectory: true), ancestor)
                    ancestor = (ancestor as NSString).deletingLastPathComponent
                }
            }
        }

        /// `levels` under `base`, each level spelled as a folder already met, else as the listing of
        /// its parent spells it, else as rendered. Lists each parent not listed yet.
        mutating func folder(
            _ levels: [String],
            under base: String,
            isCaseSensitive rule: Bool,
            listing: inout FolderListing
        ) -> (folder: URL, path: String) {
            var key = Self.key(base, rule)
            var current = known[key] ?? (URL(fileURLWithPath: base, isDirectory: true), base)

            for level in levels {
                key += (key.hasSuffix("/") ? "" : "/") + FolderListing.fold(level, isCaseSensitive: rule)

                if let found = known[key] {
                    current = found
                    continue
                }

                let parent = current.path

                if !listing.isListed(folderPath: parent) {
                    listing.list([URL(fileURLWithPath: parent, isDirectory: true)], isCaseSensitive: rule)
                }

                let name = listing.spelling(of: level, inFolderPath: parent) ?? level
                let path = parent.hasSuffix("/") ? parent + name : parent + "/" + name
                current = (URL(fileURLWithPath: path, isDirectory: true), path)
                known[key] = current
            }

            return current
        }

        /// The rule is part of the key, so one folder met under both rules is two entries.
        private static func key(_ path: String, _ isCaseSensitive: Bool) -> String {
            (isCaseSensitive ? "1" : "0") + FolderListing.folderKey(path: path, isCaseSensitive: isCaseSensitive)
        }
    }

    /// `{seq}` in the name part: the run under ``FolderPlacement/keepCurrent``, else each destination
    /// folder on its own, in unit order.
    func nameContexts(of destinations: [MovePlanBuilder.Destination]) -> [NameTemplate.RenderContext] {
        guard placement.placesFolders else {
            return destinations.indices.map { NameTemplate.RenderContext(index: $0 + 1, count: destinations.count, collection: collection) }
        }

        var counts: [String: Int] = [:]
        var positions: [Int] = []
        positions.reserveCapacity(destinations.count)

        for destination in destinations {
            let position = counts[destination.path, default: 0] + 1
            counts[destination.path] = position
            positions.append(position)
        }

        return zip(positions, destinations).map { position, destination in
            NameTemplate.RenderContext(index: position, count: counts[destination.path] ?? position, collection: collection)
        }
    }

    /// `paths` and every folder between each and the root, the root included, so a listed parent
    /// answers for a child that does not exist.
    static func withAncestors(_ paths: Set<String>, below rootPath: String) -> Set<String> {
        var result = paths

        for path in paths {
            var candidate = (path as NSString).deletingLastPathComponent

            while candidate.utf8.count >= rootPath.utf8.count, result.insert(candidate).inserted {
                candidate = (candidate as NSString).deletingLastPathComponent
            }
        }

        return result
    }
}

#endif
