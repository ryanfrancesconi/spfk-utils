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
    /// Each unit's folder. A rendered folder matching one already known by the root's case rule, a
    /// source folder or an earlier unit's, takes that spelling, and folders not listed yet are read.
    mutating func destinations(of units: [MovePlanBuilder.Unit]) -> [MovePlanBuilder.Destination] {
        let prepared = builder.prepared

        guard case let .template(folderTemplate, root) = placement else {
            return units.map {
                let lead = prepared[$0[0]]
                return MovePlanBuilder.Destination(folder: lead.folder, path: lead.folderPath, isCaseSensitive: lead.isCaseSensitive)
            }
        }

        let rule = root.isCaseSensitive
        let rootPath = FolderListing.path(of: root.url)
        var spelling: [String: (folder: URL, path: String)] = [:]

        for (path, folder) in builder.sourceFolders {
            spelling[FolderListing.folderKey(path: path, isCaseSensitive: rule)] = (folder, path)
        }

        var folders: [(folder: URL, path: String)] = []
        var unlisted: Set<String> = []
        folders.reserveCapacity(units.count)

        for (offset, unit) in units.enumerated() {
            let context = NameTemplate.RenderContext(index: offset + 1, count: units.count, collection: collection)
            let levels = folderTemplate.renderLevels(values: prepared[unit[0]].input.values, context: context)
            let path = levels.reduce(rootPath) { $0.hasSuffix("/") ? $0 + $1 : $0 + "/" + $1 }
            let key = FolderListing.folderKey(path: path, isCaseSensitive: rule)

            if let known = spelling[key] {
                folders.append(known)
                continue
            }

            let folder = (folder: URL(fileURLWithPath: path, isDirectory: true), path: path)
            spelling[key] = folder
            folders.append(folder)

            if !listing.isListed(folderPath: path) {
                unlisted.insert(path)
            }
        }

        if unlisted.isNotEmpty {
            listing.list(Self.withAncestors(unlisted, below: rootPath).map { URL(fileURLWithPath: $0, isDirectory: true) }, isCaseSensitive: rule)
        }

        return folders.map {
            MovePlanBuilder.Destination(folder: $0.folder, path: $0.path, isCaseSensitive: listing.isCaseSensitive(folderPath: $0.path))
        }
    }

    /// `{seq}` in the name part: the run under ``FolderPlacement/keepCurrent``, else each destination
    /// folder on its own, in unit order.
    func nameContexts(of destinations: [MovePlanBuilder.Destination]) -> [NameTemplate.RenderContext] {
        guard case .template = placement else {
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
    private static func withAncestors(_ paths: Set<String>, below rootPath: String) -> Set<String> {
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
