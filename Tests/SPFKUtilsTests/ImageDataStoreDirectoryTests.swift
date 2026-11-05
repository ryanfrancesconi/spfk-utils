// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import SPFKBase
import SPFKTesting
import Testing

@testable import SPFKUtils

/// A file where a store's directory goes would leave the store writing nowhere, so building it
/// has to fail.
@Suite(.tags(.file))
final class ImageDataStoreDirectoryTests: BinTestCase {
    private func plantFile(named name: String) throws {
        let data = bin.appendingPathComponent("Data", isDirectory: true)
        try FileManager.default.createDirectory(at: data, withIntermediateDirectories: true)
        try Data("not a directory".utf8).write(to: data.appendingPathComponent(name))
    }

    @Test func aFileWhereTheStoreGoesFailsTheStore() throws {
        try plantFile(named: "Image")

        #expect(throws: (any Error).self) {
            _ = try ImageDataStore(inDirectory: self.bin)
        }
    }
}
