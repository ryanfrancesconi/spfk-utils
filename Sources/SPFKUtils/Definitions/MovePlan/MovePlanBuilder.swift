// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)

import Foundation
import SPFKBase
import SPFKFileSystem
import UniformTypeIdentifiers

/// Turns a selection, a name template and a ``FolderPlacement`` into a ``MovePlan``, numbering
/// names that are taken rather than refusing them.
///
/// Prepare one per selection, then plan each template against it. Claims are made against a
/// ``FolderListing`` and the run's own earlier claims. A preview reads only destination folders not
/// listed before, once each for the builder's lifetime; ``plan(template:placement:collection:)``
/// adds the disk check a run needs before moving or copying.
public struct MovePlanBuilder: Sendable {
    let prepared: [Prepared]
    var listing: FolderListing

    /// Inputs that move as another input's companion.
    let isCompanionInput: [Bool]

    /// Each input's RAW-and-other-formats group, shared by inputs of one base name in one folder.
    let siblingGroup: [Int]
    let siblingGroupCount: Int

    let indexByURL: [URL: Int]

    /// Each distinct source folder by its path, whose spelling a destination folder matching it by
    /// case rule takes.
    let sourceFolders: [String: URL]

    /// - Parameters:
    ///   - inputs: in display order, which `{seq}` follows.
    ///   - companions: each input's, from `FileCompanions.resolve`. An input listed as another's
    ///     companion moves with it and is no entry of its own.
    public init(inputs: [MovePlanInput], companions: [URL: [URL]], listing: FolderListing) {
        self.listing = listing

        let owners = Set(companions.keys)
        let companionURLs = Set(companions.values.joined()).subtracting(owners)
        isCompanionInput = inputs.map { companionURLs.contains($0.url) }

        var rawByExtension: [String: Bool] = [:]
        var groupByKey: [String: Int] = [:]
        var groups: [Int] = []

        prepared = inputs.map { input in
            let pathExtension = input.url.pathExtension

            let isRAW = rawByExtension[pathExtension.lowercased()] ?? {
                let isRAW = UTType(filenameExtension: pathExtension)?.conforms(to: .rawImage) ?? false
                rawByExtension[pathExtension.lowercased()] = isRAW
                return isRAW
            }()

            let prepared = Prepared(input: input, companions: companions[input.url, default: []], isRAW: isRAW, listing: listing)
            let siblingKey = prepared.folderPath + "/" + prepared.baseName.decomposedStringWithCanonicalMapping.lowercased()

            if let group = groupByKey[siblingKey] {
                groups.append(group)
            } else {
                groupByKey[siblingKey] = groupByKey.count
                groups.append(groupByKey.count - 1)
            }

            return prepared
        }

        siblingGroup = groups
        siblingGroupCount = groupByKey.count
        sourceFolders = Dictionary(prepared.map { ($0.folderPath, $0.folder) }, uniquingKeysWith: { first, _ in first })
        indexByURL = Dictionary(inputs.enumerated().map { ($1.url, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// A plan by the listing alone, for a preview redrawn on each keystroke.
    public struct Preview: Sendable, Equatable {
        public let plan: MovePlan

        /// Sources whose rendered name was taken, so they were numbered.
        public let numbered: Set<URL>

        /// Candidate pairs not compared yet, whose second source was numbered meanwhile.
        public let unresolved: Set<DuplicateVerdicts.Pair>
    }

    /// - Parameters:
    ///   - duplicates: verdicts on the candidate pairs compared so far. Under a folder placement, a
    ///     source of the same size as the one holding its destination is a candidate.
    ///   - operation: under ``MoveOperation/copy`` no file gives up its name, so a copy rendering
    ///     its source's own path is numbered.
    public mutating func preview(
        template: NameTemplate,
        placement: FolderPlacement = .keepCurrent,
        collection: String = "",
        duplicates: DuplicateVerdicts = DuplicateVerdicts(),
        operation: MoveOperation = .move
    ) -> Preview {
        var pass = Pass(builder: self, template: template, placement: placement, collection: collection, duplicates: duplicates, operation: operation)
        let plan = pass.settled()
        listing = pass.listing
        return Preview(plan: plan, numbered: pass.numbered, unresolved: pass.unresolved)
    }

    /// The plan checked against the disk, which a listing can be out of step with, and ready for
    /// `FileCommands.move` or, under ``MoveOperation/copy``, `FileCommands.copy`.
    public mutating func plan(
        template: NameTemplate,
        placement: FolderPlacement = .keepCurrent,
        collection: String = "",
        duplicates: DuplicateVerdicts = DuplicateVerdicts(),
        operation: MoveOperation = .move
    ) -> MovePlan {
        var pass = Pass(builder: self, template: template, placement: placement, collection: collection, duplicates: duplicates, operation: operation)
        defer { listing = pass.listing }

        while true {
            let plan = pass.settled()
            let conflicts = switch operation {
            case .move: FileCommands.moveConflicts(in: plan)
            case .copy: FileCommands.copyConflicts(in: plan)
            }

            guard conflicts.isNotEmpty else { return plan }

            for (source, error) in conflicts {
                pass.learn(error, refusing: source)
            }
        }
    }

    /// The bytes copying `plan` under `root` writes: its planned files that `root` cannot clone.
    /// Companions are not counted.
    public func bytesToCopy(_ plan: MovePlan, root: MoveRoot) -> UInt64 {
        let sources = plan.groups.compactMap { group -> (size: UInt64?, volume: URL?)? in
            guard let index = indexByURL[group.source] else { return nil }
            let input = prepared[index].input
            return (input.fileSize, input.volume)
        }

        return MoveRoot.bytesToCopy(sources, rootVolume: root.volume, rootClones: root.supportsCloning)
    }

    /// One template's checked plan, from a builder used once.
    public static func build(
        inputs: [MovePlanInput],
        companions: [URL: [URL]],
        template: NameTemplate,
        placement: FolderPlacement = .keepCurrent,
        collection: String = "",
        listing: FolderListing
    ) -> MovePlan {
        var builder = MovePlanBuilder(inputs: inputs, companions: companions, listing: listing)
        return builder.plan(template: template, placement: placement, collection: collection)
    }
}

// MARK: - Prepared

extension MovePlanBuilder {
    /// An input's paths as the builder compares them, worked out once so a template is planned in
    /// strings and only its groups become URLs.
    struct Prepared: Sendable {
        struct Companion: Sendable {
            let url: URL

            /// What follows the owner's new base in the companion's name: `.xmp`, or `_O.aae` for an
            /// original's edit record beside the owner's own.
            let tail: String

            let key: String
        }

        let input: MovePlanInput
        let folder: URL
        let folderPath: String
        let isCaseSensitive: Bool
        let name: String
        let baseName: String
        let pathExtension: String
        let key: String
        let isRAW: Bool
        let companions: [Companion]

        /// Its own and its companions' extensions, lowercased and sorted, since a name free for one
        /// extension is not for another.
        let extensions: [String]

        init(input: MovePlanInput, companions found: [URL], isRAW: Bool, listing: FolderListing) {
            self.input = input
            self.isRAW = isRAW

            folder = input.url.deletingLastPathComponent()
            folderPath = FolderListing.path(of: folder)
            isCaseSensitive = listing.isCaseSensitive(folderPath: folderPath)
            name = input.url.lastPathComponent
            baseName = input.url.deletingPathExtension().lastPathComponent
            pathExtension = input.url.pathExtension
            key = FolderListing.key(name: name, folderPath: folderPath, isCaseSensitive: isCaseSensitive)

            // The tails come from the shared naming rule applied once with the owner's own name,
            // which depends on the companions' extensions and not on the base.
            let base = baseName
            let destinations = URL.companionDestinations(found, forOwner: input.url)

            companions = zip(found, destinations).map { companion, destination in
                let destinationName = destination.lastPathComponent
                let tail = destinationName.hasPrefix(base) ? String(destinationName.dropFirst(base.count)) : "." + companion.pathExtension
                return Companion(url: companion, tail: tail, key: listing.key(companion))
            }

            extensions = ([pathExtension] + found.map(\.pathExtension)).map { $0.lowercased() }.sorted()
        }

        /// The file's name under `base`, keeping its extension.
        func name(base: String) -> String {
            pathExtension.isEmpty ? base : base + "." + pathExtension
        }

        func group(base: String, in destination: URL) -> MovePlan.Group {
            MovePlan.Group(
                source: input.url,
                destination: destination.appendingPathComponent(name(base: base), isDirectory: false),
                companions: companions.map {
                    MovePlan.CompanionMove(from: $0.url, to: destination.appendingPathComponent(base + $0.tail, isDirectory: false))
                }
            )
        }
    }
}

#endif
