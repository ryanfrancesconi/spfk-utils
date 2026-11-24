// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import SPFKBase
import SPFKTesting
import Testing

@testable import SPFKUtils

/// Byte comparison of candidate pairs, over real files in the bin.
@Suite(.tags(.renameOrganize, .file), .serialized)
final class DuplicateVerdictTests: BinTestCase {
    private func file(_ name: String, _ bytes: [UInt8]) throws -> URL {
        let url = bin.appendingPathComponent(name)
        try Data(bytes).write(to: url)
        return url
    }

    @Test func identicalBytesCompareTrueAndAOneByteDifferenceFalse() async throws {
        let a = try file("a.jpg", [1, 2, 3, 4])
        let same = try file("same.jpg", [1, 2, 3, 4])
        let differs = try file("differs.jpg", [1, 2, 3, 5])
        let identical = DuplicateVerdicts.Pair(first: a, second: same)
        let different = DuplicateVerdicts.Pair(first: a, second: differs)

        var verdicts = DuplicateVerdicts()
        try await verdicts.compare([identical, different])

        #expect(verdicts[identical] == true)
        #expect(verdicts[different] == false)
    }

    /// A pair is read once: a later change to either file is not seen by a second request.
    @Test func aPairIsComparedOnce() async throws {
        let a = try file("a.jpg", [1, 2, 3])
        let b = try file("b.jpg", [1, 2, 3])
        let pair = DuplicateVerdicts.Pair(first: a, second: b)

        var verdicts = DuplicateVerdicts()
        try await verdicts.compare([pair])
        try Data([9, 9, 9]).write(to: b)
        try await verdicts.compare([pair, pair])

        #expect(verdicts[pair] == true)
    }
}
