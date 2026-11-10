// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKBase
import SPFKFileSystem
import SPFKTesting
import Testing

@testable import SPFKUtils

@Suite(.tags(.file, .conversion))
final class BatchOutputClaimsTests: BinTestCase {
    private func file(_ name: String) -> URL {
        bin.appending(component: name, directoryHint: .notDirectory)
    }

    private func outputs(_ claims: [BatchOutputClaims.Claim], ownInputIsTaken: Bool = false) throws -> [String] {
        try BatchOutputClaims.resolve(claims, ownInputIsTaken: ownInputIsTaken).map { try $0.get().output.lastPathComponent }
    }

    /// A converter refuses an output that is its own input by identity, so by default it is left for it to refuse.
    @Test func anOutputNamingItsOwnInputIsKeptByDefault() throws {
        let claim = BatchOutputClaims.Claim(output: file("a.wav"), conflictScheme: .overwrite, inputs: [file("a.wav")])

        #expect(try outputs([claim]) == ["a.wav"])
    }

    /// Writing beside the original numbers the name rather than replacing the original.
    @Test(arguments: FileConflictScheme.allCases)
    func anOutputNamingItsOwnInputIsNumberedWhenAsked(scheme: FileConflictScheme) throws {
        let claim = BatchOutputClaims.Claim(output: file("a.wav"), conflictScheme: scheme, inputs: [file("a.wav")])

        let resolved = try #require(try BatchOutputClaims.resolve([claim], ownInputIsTaken: true).first?.get())

        #expect(resolved.output != file("a.wav"))
        #expect(resolved.conflictScheme == .overwrite)
    }

    @Test func anotherItemsInputIsTakenEitherWay() throws {
        let claims = [
            BatchOutputClaims.Claim(output: file("b.wav"), conflictScheme: .overwrite, inputs: [file("a.wav")]),
            BatchOutputClaims.Claim(output: file("x.wav"), conflictScheme: .overwrite, inputs: [file("b.wav")]),
        ]

        #expect(try outputs(claims).first != "b.wav")
        #expect(try outputs(claims, ownInputIsTaken: true).first != "b.wav")
    }
}
