// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)

import Foundation
import SPFKBase
import SPFKFileSystem

extension MovePlanBuilder {
    /// One file, or a RAW and its other formats selected together, named as one: indexes into
    /// ``prepared``.
    typealias Unit = [Int]

    private enum ClaimResult {
        case claimed(Unit, base: String)
        case skipped(MoveSkipReason)
    }

    /// One template's planning, holding what earlier rounds of it found.
    struct Pass {
        let builder: MovePlanBuilder
        let template: NameTemplate
        let placement: FolderPlacement
        let collection: String
        let duplicates: DuplicateVerdicts
        let operation: MoveOperation

        /// The builder's listing, grown by each destination folder a round reads.
        var listing: FolderListing

        /// Skips found while naming or claiming, and from the disk check, which hold on every later
        /// round, keyed by input index.
        var forced: [Int: MoveSkipReason] = [:]

        /// Names the disk check found taken although the listing did not hold them.
        var learnedTaken: Set<String> = []

        /// The last settled round's sources whose rendered name was numbered.
        private(set) var numbered: Set<URL> = []

        /// The last settled round's candidate pairs with no verdict.
        private(set) var unresolved: Set<DuplicateVerdicts.Pair> = []

        init(
            builder: MovePlanBuilder,
            template: NameTemplate,
            placement: FolderPlacement,
            collection: String,
            duplicates: DuplicateVerdicts,
            operation: MoveOperation
        ) {
            self.builder = builder
            self.template = template
            self.placement = placement
            self.collection = collection
            self.duplicates = duplicates
            self.operation = operation
            listing = builder.listing
        }

        /// Repeats a round until it finds no new skip, since a skipped file stops vacating its name.
        mutating func settled() -> MovePlan {
            while true {
                let (plan, skips, numbered, unresolved) = run()

                guard skips.isNotEmpty else {
                    self.numbered = numbered
                    self.unresolved = unresolved
                    return plan
                }

                forced.merge(skips) { first, _ in first }
            }
        }

        mutating func learn(_ error: FileCommandError, refusing source: URL) {
            guard let index = builder.indexByURL[source] else { return }

            switch error {
            case let .nameInUse(url), let .companionNameInUse(url):
                guard learnedTaken.insert(listing.key(url)).inserted else {
                    forced[index] = .nameInUse(url)
                    return
                }
            case .companionNameClash:
                forced[index] = .companionNameClash
            case .locked:
                forced[index] = .locked
            case .invalidName:
                // Unreached: a rendered name is sanitized, leaving no `.` or `..`, and an empty one is skipped first.
                forced[index] = .emptyName
            case let .rollbackFailed(url, _):
                // Unreached: the disk check plans and never moves.
                forced[index] = .nameInUse(url)
            }
        }

        /// Under a copy, either file of the pair gets its row's unsaved edits written on, so the two
        /// copies differ however alike the files are.
        private func writesUnsavedEdits(_ lead: Int, _ holder: Int) -> Bool {
            operation == .copy && (builder.prepared[lead].input.hasUnsavedEdits || builder.prepared[holder].input.hasUnsavedEdits)
        }

        /// A copy only reads its source, so it skips a locked file or one on another volume, and
        /// a source's folder only when the copy is written into it.
        private func skipReason(_ index: Int) -> MoveSkipReason? {
            if let reason = forced[index] { return reason }

            let input = builder.prepared[index].input
            let isCopy = operation == .copy
            let writesSourceFolder = if case .template = placement { !isCopy } else { true }

            if input.isMissing { return .missing }
            if input.isLocked, !isCopy { return .locked }
            if input.isBusy { return .busy }
            if !input.isFolderWritable, writesSourceFolder { return .sourceFolderNotWritable }
            if input.isInsidePackage, writesSourceFolder { return .insidePackage }

            if !isCopy, case let .template(_, root) = placement, let volume = input.volume, let rootVolume = root.volume, volume != rootVolume {
                return .otherVolume
            }

            return nil
        }

        // MARK: Run

        private mutating func run() -> (MovePlan, [Int: MoveSkipReason], Set<URL>, Set<DuplicateVerdicts.Pair>) {
            let prepared = builder.prepared
            var entries = [MovePlan.Entry?](repeating: nil, count: prepared.count)
            var skips: [Int: MoveSkipReason] = [:]
            var active: [Int] = []

            for index in prepared.indices where !builder.isCompanionInput[index] {
                if let reason = skipReason(index) {
                    entries[index] = .skipped(prepared[index].input.url, reason)
                } else {
                    active.append(index)
                }
            }

            let units = units(of: active)
            let destinations = destinations(of: units)
            let contexts = nameContexts(of: destinations)
            var named: [(unit: Unit, base: String, destination: Destination, isMoving: Bool)] = []
            named.reserveCapacity(units.count)

            for (offset, unit) in units.enumerated() {
                let base = template.render(values: prepared[unit[0]].input.values, context: contexts[offset])

                guard base.isNotEmpty else {
                    unit.forEach { skips[$0] = .emptyName }
                    continue
                }

                let destination = destinations[offset]
                let isMoving = operation == .copy || unit.contains { destination.path != prepared[$0].folderPath || prepared[$0].name(base: base) != prepared[$0].name }
                named.append((unit, base, destination, isMoving))
            }

            // A copy leaves its source in place, so its name stays taken.
            var vacating: Set<String> = []

            for (unit, _, _, isMoving) in named where isMoving && operation == .move {
                for member in unit {
                    vacating.insert(prepared[member].key)
                    prepared[member].companions.forEach { vacating.insert($0.key) }
                }
            }

            var claimed: Set<String> = []
            var nextNumber: [String: Int] = [:]
            var numbered: Set<URL> = []
            var unresolved: Set<DuplicateVerdicts.Pair> = []

            // Under a folder placement, the source holding each name: one already in place, or the
            // first to claim it unnumbered.
            var holders: [String: Int] = [:]
            let comparesDuplicates = placement.placesFolders

            if comparesDuplicates {
                for (unit, _, _, isMoving) in named where !isMoving {
                    unit.forEach { holders[prepared[$0].key] = $0 }
                }
            }

            for (unit, base, destination, isMoving) in named {
                guard isMoving else {
                    for member in unit {
                        entries[member] = .alreadyInPlace(prepared[member].input.url)
                        claimed.insert(prepared[member].key)
                        prepared[member].companions.forEach { claimed.insert($0.key) }
                    }
                    continue
                }

                let lead = unit[0]
                let destinationKey = FolderListing.key(name: prepared[lead].name(base: base), folderPath: destination.path, isCaseSensitive: destination.isCaseSensitive)

                if comparesDuplicates, unit.count == 1, let holder = holders[destinationKey], holder != lead,
                   let size = prepared[lead].input.fileSize, size == prepared[holder].input.fileSize,
                   !writesUnsavedEdits(lead, holder) {
                    let pair = DuplicateVerdicts.Pair(first: prepared[holder].input.url, second: prepared[lead].input.url)

                    switch duplicates[pair] {
                    case true?:
                        skips[lead] = .duplicate(of: prepared[holder].input.url)
                        continue
                    case false?:
                        break
                    case nil:
                        unresolved.insert(pair)
                    }
                }

                switch claim(unit, base: base, in: destination, claimed: &claimed, nextNumber: &nextNumber, vacating: vacating) {
                case let .claimed(unit, claimedBase):
                    if comparesDuplicates, claimedBase == base, holders[destinationKey] == nil {
                        holders[destinationKey] = lead
                    }

                    unit.forEach { entries[$0] = .move(prepared[$0].group(base: claimedBase, in: destination.folder)) }

                    if claimedBase != base {
                        unit.forEach { numbered.insert(prepared[$0].input.url) }
                    }
                case let .skipped(reason):
                    unit.forEach { skips[$0] = reason }
                }
            }

            return (MovePlan(entries: entries.compactMap { $0 }), skips, numbered, unresolved)
        }

        /// The first free numbering of `base` for the unit in `destination`, claimed.
        private func claim(
            _ unit: Unit,
            base: String,
            in destination: Destination,
            claimed: inout Set<String>,
            nextNumber: inout [String: Int],
            vacating: Set<String>
        ) -> ClaimResult {
            let prepared = builder.prepared
            let lead = prepared[unit[0]]

            func isTaken(_ key: String) -> Bool {
                claimed.contains(key) || learnedTaken.contains(key) || (listing.holds(key: key) && !vacating.contains(key))
            }

            func key(_ name: String) -> String {
                FolderListing.key(name: name, folderPath: destination.path, isCaseSensitive: destination.isCaseSensitive)
            }

            // Every number below the last one claimed for this name was taken then and still is, so
            // many files rendering one name cost one check each rather than one per earlier file.
            let extensions = unit.count == 1 ? lead.extensions : unit.flatMap { prepared[$0].extensions }.sorted()
            let numberKey = key(lead.name(base: base)) + "|" + extensions.joined(separator: ",")
            let first = nextNumber[numberKey] ?? 0

            for number in first ... first + 100_000 {
                let numbered = number == 0 ? base : "\(base) \(number)"

                guard numbered.utf8.count <= NameTemplate.maximumNameByteCount else { return .skipped(.overByteCap) }

                var keys: [String] = []

                for member in unit {
                    let file = prepared[member]
                    keys.append(key(file.name(base: numbered)))
                    file.companions.forEach { keys.append(key(numbered + $0.tail)) }
                }

                guard keys.count == 1 || Set(keys).count == keys.count else { return .skipped(.companionNameClash) }
                guard !keys.contains(where: isTaken) else { continue }

                claimed.formUnion(keys)
                nextNumber[numberKey] = number + 1
                return .claimed(unit, base: numbered)
            }

            return .skipped(.nameInUse(destination.folder.appendingPathComponent(lead.name(base: base), isDirectory: false)))
        }

        /// Each input alone, except a RAW and its other formats in one folder, which name together.
        private func units(of active: [Int]) -> [Unit] {
            let prepared = builder.prepared
            var hasRAW = [Bool](repeating: false, count: builder.siblingGroupCount)
            var hasOther = hasRAW

            for index in active {
                if prepared[index].isRAW {
                    hasRAW[builder.siblingGroup[index]] = true
                } else {
                    hasOther[builder.siblingGroup[index]] = true
                }
            }

            var units: [Unit] = []
            var unitByGroup: [Int: Int] = [:]
            units.reserveCapacity(active.count)

            for index in active {
                let group = builder.siblingGroup[index]

                guard hasRAW[group], hasOther[group] else {
                    units.append([index])
                    continue
                }

                if let unit = unitByGroup[group] {
                    units[unit].append(index)
                } else {
                    unitByGroup[group] = units.count
                    units.append([index])
                }
            }

            return units
        }
    }
}

#endif
