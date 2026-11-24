// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)

import Foundation
import SPFKBase
import SPFKFileSystem

extension MovePlanBuilder {
    /// One file, or a RAW and its other formats selected together, named as one: indexes into
    /// ``prepared``.
    private typealias Unit = [Int]

    private enum ClaimResult {
        case claimed(Unit, base: String)
        case skipped(MoveSkipReason)
    }

    /// One template's planning, holding what earlier rounds of it found.
    struct Pass {
        let builder: MovePlanBuilder
        let template: NameTemplate
        let collection: String

        /// Skips found while naming or claiming, and from the disk check, which hold on every later
        /// round, keyed by input index.
        var forced: [Int: MoveSkipReason] = [:]

        /// Names the disk check found taken although the listing did not hold them.
        var learnedTaken: Set<String> = []

        /// The last settled round's sources whose rendered name was numbered.
        private(set) var numbered: Set<URL> = []

        init(builder: MovePlanBuilder, template: NameTemplate, collection: String) {
            self.builder = builder
            self.template = template
            self.collection = collection
        }

        /// Repeats a round until it finds no new skip, since a skipped file stops vacating its name.
        mutating func settled() -> MovePlan {
            while true {
                let (plan, skips, numbered) = run()

                guard skips.isNotEmpty else {
                    self.numbered = numbered
                    return plan
                }

                forced.merge(skips) { first, _ in first }
            }
        }

        mutating func learn(_ error: FileCommandError, refusing source: URL) {
            guard let index = builder.indexByURL[source] else { return }

            switch error {
            case let .nameInUse(url), let .companionNameInUse(url):
                guard learnedTaken.insert(builder.listing.key(url)).inserted else {
                    forced[index] = .nameInUse(url)
                    return
                }
            case .companionNameClash:
                forced[index] = .companionNameClash
            case .locked:
                forced[index] = .locked
            case .invalidName:
                forced[index] = .emptyName
            case let .rollbackFailed(url, _):
                forced[index] = .nameInUse(url)
            }
        }

        private func skipReason(_ index: Int) -> MoveSkipReason? {
            if let reason = forced[index] { return reason }

            let input = builder.prepared[index].input
            if input.isMissing { return .missing }
            if input.isLocked { return .locked }
            if input.isBusy { return .busy }
            if !input.isFolderWritable { return .sourceFolderNotWritable }
            if input.isInsidePackage { return .insidePackage }
            return nil
        }

        // MARK: Run

        private func run() -> (MovePlan, [Int: MoveSkipReason], Set<URL>) {
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
            var named: [(unit: Unit, base: String, isMoving: Bool)] = []
            named.reserveCapacity(units.count)

            for (offset, unit) in units.enumerated() {
                let context = NameTemplate.RenderContext(index: offset + 1, count: units.count, collection: collection)
                let base = template.render(values: prepared[unit[0]].input.values, context: context)

                guard base.isNotEmpty else {
                    unit.forEach { skips[$0] = .emptyName }
                    continue
                }

                let isMoving = unit.contains { prepared[$0].name(base: base) != prepared[$0].name }
                named.append((unit, base, isMoving))
            }

            var vacating: Set<String> = []

            for (unit, _, isMoving) in named where isMoving {
                for member in unit {
                    vacating.insert(prepared[member].key)
                    prepared[member].companions.forEach { vacating.insert($0.key) }
                }
            }

            var claimed: Set<String> = []
            var nextNumber: [String: Int] = [:]
            var numbered: Set<URL> = []

            for (unit, base, isMoving) in named {
                guard isMoving else {
                    for member in unit {
                        entries[member] = .alreadyInPlace(prepared[member].input.url)
                        claimed.insert(prepared[member].key)
                        prepared[member].companions.forEach { claimed.insert($0.key) }
                    }
                    continue
                }

                switch claim(unit, base: base, claimed: &claimed, nextNumber: &nextNumber, vacating: vacating) {
                case let .claimed(unit, claimedBase):
                    unit.forEach { entries[$0] = .move(prepared[$0].group(base: claimedBase)) }

                    if claimedBase != base {
                        unit.forEach { numbered.insert(prepared[$0].input.url) }
                    }
                case let .skipped(reason):
                    unit.forEach { skips[$0] = reason }
                }
            }

            return (MovePlan(entries: entries.compactMap { $0 }), skips, numbered)
        }

        /// The first free numbering of `base` for the unit, claimed.
        private func claim(
            _ unit: Unit,
            base: String,
            claimed: inout Set<String>,
            nextNumber: inout [String: Int],
            vacating: Set<String>
        ) -> ClaimResult {
            let prepared = builder.prepared
            let lead = prepared[unit[0]]

            func isTaken(_ key: String) -> Bool {
                claimed.contains(key) || learnedTaken.contains(key) || (builder.listing.holds(key: key) && !vacating.contains(key))
            }

            // Every number below the last one claimed for this name was taken then and still is, so
            // many files rendering one name cost one check each rather than one per earlier file.
            let extensions = unit.count == 1 ? lead.extensions : unit.flatMap { prepared[$0].extensions }.sorted()
            let numberKey = lead.key(for: lead.name(base: base)) + "|" + extensions.joined(separator: ",")
            let first = nextNumber[numberKey] ?? 0

            for number in first ... first + 100_000 {
                let numbered = number == 0 ? base : "\(base) \(number)"

                guard numbered.utf8.count <= NameTemplate.maximumNameByteCount else { return .skipped(.overByteCap) }

                var keys: [String] = []

                for member in unit {
                    let file = prepared[member]
                    keys.append(file.key(for: file.name(base: numbered)))
                    file.companions.forEach { keys.append(file.key(for: numbered + $0.tail)) }
                }

                guard keys.count == 1 || Set(keys).count == keys.count else { return .skipped(.companionNameClash) }
                guard !keys.contains(where: isTaken) else { continue }

                claimed.formUnion(keys)
                nextNumber[numberKey] = number + 1
                return .claimed(unit, base: numbered)
            }

            return .skipped(.nameInUse(lead.folder.appendingPathComponent(lead.name(base: base), isDirectory: false)))
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
