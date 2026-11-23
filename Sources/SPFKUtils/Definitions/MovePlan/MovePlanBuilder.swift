// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)

import Foundation
import SPFKBase
import SPFKFileSystem
import UniformTypeIdentifiers

/// Turns a selection and a name template into a ``MovePlan``, numbering names that are taken
/// rather than refusing them. Every file stays in its own folder.
///
/// Claims are made against a ``FolderListing`` and the run's own earlier claims, never by statting
/// candidates, so a re-render on each keystroke costs no disk access until the last check.
public enum MovePlanBuilder {
    /// - Parameters:
    ///   - inputs: in display order, which `{seq}` follows.
    ///   - companions: each input's, from `FileCompanions.resolve`. An input listed as another's
    ///     companion moves with it and is no entry of its own.
    public static func build(
        inputs: [MovePlanInput],
        companions: [URL: [URL]],
        template: NameTemplate,
        collection: String = "",
        listing: FolderListing
    ) -> MovePlan {
        var pass = Pass(inputs: inputs, companions: companions, template: template, collection: collection, listing: listing)

        while true {
            let plan = pass.settled()
            let conflicts = FileCommands.moveConflicts(in: plan)

            guard conflicts.isNotEmpty else { return plan }

            for (source, error) in conflicts {
                pass.learn(error, refusing: source)
            }
        }
    }
}

// MARK: - Pass

extension MovePlanBuilder {
    /// One file, or a RAW and its other formats selected together, named as one.
    private struct Unit {
        var members: [MovePlanInput]
    }

    private enum ClaimResult {
        case claimed([MovePlan.Group])
        case skipped(MoveSkipReason)
    }

    private struct Pass {
        let inputs: [MovePlanInput]
        let companions: [URL: [URL]]
        let template: NameTemplate
        let collection: String
        let listing: FolderListing

        /// Inputs that move as another input's companion.
        let companionInputs: Set<URL>

        /// Skips found while naming or claiming, and from the disk check, which hold on every later pass.
        var forced: [URL: MoveSkipReason] = [:]

        /// Names the disk check found taken although the listing did not hold them.
        var learnedTaken: Set<String> = []

        init(inputs: [MovePlanInput], companions: [URL: [URL]], template: NameTemplate, collection: String, listing: FolderListing) {
            self.inputs = inputs
            self.companions = companions
            self.template = template
            self.collection = collection
            self.listing = listing

            let owners = Set(companions.keys)
            companionInputs = Set(companions.values.joined()).subtracting(owners)
        }

        /// Repeats a pass until it finds no new skip, since a skipped file stops vacating its name.
        mutating func settled() -> MovePlan {
            while true {
                let (plan, skips) = run()
                guard skips.isNotEmpty else { return plan }
                forced.merge(skips) { first, _ in first }
            }
        }

        mutating func learn(_ error: FileCommandError, refusing source: URL) {
            switch error {
            case let .nameInUse(url), let .companionNameInUse(url):
                guard learnedTaken.insert(listing.key(url)).inserted else {
                    forced[source] = .nameInUse(url)
                    return
                }
            case .locked:
                forced[source] = .locked
            case .invalidName:
                forced[source] = .emptyName
            case let .rollbackFailed(url, _):
                forced[source] = .nameInUse(url)
            }
        }

        private func skipReason(_ input: MovePlanInput) -> MoveSkipReason? {
            if let reason = forced[input.url] { return reason }
            if input.isMissing { return .missing }
            if input.isLocked { return .locked }
            if input.isBusy { return .busy }
            if !input.isFolderWritable { return .sourceFolderNotWritable }
            if input.isInsidePackage { return .insidePackage }
            return nil
        }

        // MARK: Run

        private func run() -> (MovePlan, [URL: MoveSkipReason]) {
            var entries: [URL: MovePlan.Entry] = [:]
            var skips: [URL: MoveSkipReason] = [:]
            var named: [Unit] = []

            for input in inputs where !companionInputs.contains(input.url) {
                if let reason = skipReason(input) {
                    entries[input.url] = .skipped(input.url, reason)
                }
            }

            let units = Self.units(of: inputs.filter { entries[$0.url] == nil && !companionInputs.contains($0.url) })
            var bases: [String] = []

            for (offset, unit) in units.enumerated() {
                let context = NameTemplate.RenderContext(index: offset + 1, count: units.count, collection: collection)
                let base = template.render(values: unit.members[0].values, context: context)

                guard base.isNotEmpty else {
                    unit.members.forEach { skips[$0.url] = .emptyName }
                    continue
                }

                named.append(unit)
                bases.append(base)
            }

            var vacating: Set<String> = []

            for (unit, base) in zip(named, bases) where isMoving(unit, base: base) {
                for member in unit.members {
                    vacating.insert(listing.key(member.url))
                    companions[member.url, default: []].forEach { vacating.insert(listing.key($0)) }
                }
            }

            var claimed: Set<String> = []
            var nextNumber: [String: Int] = [:]

            for (unit, base) in zip(named, bases) {
                guard isMoving(unit, base: base) else {
                    for member in unit.members {
                        entries[member.url] = .alreadyInPlace(member.url)
                        claimed.insert(listing.key(member.url))
                        companions[member.url, default: []].forEach { claimed.insert(listing.key($0)) }
                    }
                    continue
                }

                switch claim(unit, base: base, claimed: &claimed, nextNumber: &nextNumber, vacating: vacating) {
                case let .claimed(groups):
                    groups.forEach { entries[$0.source] = .move($0) }
                case let .skipped(reason):
                    unit.members.forEach { skips[$0.url] = reason }
                }
            }

            let ordered = inputs.compactMap { entries[$0.url] }
            return (MovePlan(entries: ordered), skips)
        }

        /// The unit's groups under the first free numbering of `base`, claimed.
        private func claim(
            _ unit: Unit,
            base: String,
            claimed: inout Set<String>,
            nextNumber: inout [String: Int],
            vacating: Set<String>
        ) -> ClaimResult {
            func isTaken(_ url: URL) -> Bool {
                let key = listing.key(url)
                return claimed.contains(key) || learnedTaken.contains(key) || (listing.contains(url) && !vacating.contains(key))
            }

            // Every number below the last one claimed for this name was taken then and still is, so
            // many files rendering one name cost one check each rather than one per earlier file.
            // Keyed by every extension the unit claims, since a name free for one is not for another.
            let extensions = unit.members.flatMap { member in
                [member.url.pathExtension] + companions[member.url, default: []].map(\.pathExtension)
            }
            let numberKey = listing.key(destination(of: unit.members[0].url, base: base)) + "|" + extensions.map { $0.lowercased() }.sorted().joined(separator: ",")
            let first = nextNumber[numberKey] ?? 0

            for number in first ... first + 100_000 {
                let numbered = number == 0 ? base : "\(base) \(number)"

                guard numbered.utf8.count <= NameTemplate.maximumNameByteCount else { return .skipped(.overByteCap) }

                let groups = unit.members.map { member in
                    let destination = destination(of: member.url, base: numbered)
                    let moves = companions[member.url, default: []].map {
                        MovePlan.CompanionMove(from: $0, to: $0.companionDestination(forOwner: destination))
                    }
                    return MovePlan.Group(source: member.url, destination: destination, companions: moves)
                }

                let keys = groups.flatMap { [listing.key($0.destination)] + $0.companions.map { listing.key($0.to) } }

                guard Set(keys).count == keys.count else { return .skipped(.companionNameClash) }

                let urls = groups.flatMap { [$0.destination] + $0.companions.map(\.to) }

                guard !urls.contains(where: isTaken) else { continue }

                claimed.formUnion(keys)
                nextNumber[numberKey] = number + 1
                return .claimed(groups)
            }

            return .skipped(.nameInUse(destination(of: unit.members[0].url, base: base)))
        }

        private func isMoving(_ unit: Unit, base: String) -> Bool {
            unit.members.contains { destination(of: $0.url, base: base) != $0.url }
        }

        private func destination(of source: URL, base: String) -> URL {
            let folder = source.deletingLastPathComponent()
            let pathExtension = source.pathExtension

            return pathExtension.isEmpty
                ? folder.appendingPathComponent(base)
                : folder.appendingPathComponent(base).appendingPathExtension(pathExtension)
        }

        /// Each input alone, except a RAW and its other formats in one folder, which name together.
        private static func units(of inputs: [MovePlanInput]) -> [Unit] {
            var units: [Unit] = []
            var unitBySibling: [String: Int] = [:]

            let byBase = Dictionary(grouping: inputs, by: siblingKey)

            for input in inputs {
                let key = siblingKey(input)
                let siblings = byBase[key] ?? []
                let isPair = siblings.contains(where: isRAW) && siblings.contains(where: { !isRAW($0) })

                guard isPair else {
                    units.append(Unit(members: [input]))
                    continue
                }

                if let index = unitBySibling[key] {
                    units[index].members.append(input)
                } else {
                    unitBySibling[key] = units.count
                    units.append(Unit(members: [input]))
                }
            }

            return units
        }

        private static func siblingKey(_ input: MovePlanInput) -> String {
            let folder = input.url.deletingLastPathComponent().standardizedFileURL.path
            let base = input.url.deletingPathExtension().lastPathComponent
            return folder + "/" + base.decomposedStringWithCanonicalMapping.lowercased()
        }

        private static func isRAW(_ input: MovePlanInput) -> Bool {
            UTType(filenameExtension: input.url.pathExtension)?.conforms(to: .rawImage) ?? false
        }
    }
}

#endif
