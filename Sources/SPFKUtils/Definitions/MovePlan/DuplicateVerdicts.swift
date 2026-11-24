// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKBase

/// Whether pairs of a run's sources are byte for byte the same, each pair compared once and kept
/// for as long as the value is.
public struct DuplicateVerdicts: Sendable {
    /// Two sources taking one destination: the one holding it, then the one that would stay.
    public struct Pair: Sendable, Hashable {
        public let first: URL
        public let second: URL

        public init(first: URL, second: URL) {
            self.first = first.standardizedFileURL
            self.second = second.standardizedFileURL
        }
    }

    private var verdicts: [Pair: Bool] = [:]

    public init() {}

    /// Nil until the pair has been compared.
    public subscript(pair: Pair) -> Bool? {
        verdicts[pair]
    }

    public mutating func record(_ identical: Bool, for pair: Pair) {
        verdicts[pair] = identical
    }

    /// Compares each of `pairs` not compared before, reading the files off the caller's actor.
    public mutating func compare(_ pairs: some Sequence<Pair>) async throws {
        let pending = Array(Set(pairs).filter { verdicts[$0] == nil })

        guard pending.isNotEmpty else { return }

        let results = try await processBatch(
            count: pending.count,
            kind: .fileIO,
            name: { pending[$0].second.lastPathComponent },
            work: { index in
                (index, FileManager.default.contentsEqual(atPath: pending[index].first.path, andPath: pending[index].second.path))
            }
        )

        for (index, identical) in results {
            verdicts[pending[index]] = identical
        }
    }
}
