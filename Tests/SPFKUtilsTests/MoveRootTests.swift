// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import SPFKBase
import SPFKFileSystem
import SPFKTesting
import Testing

@testable import SPFKUtils

/// The checks a run's root passes when it is chosen, against folders in the bin.
@Suite(.tags(.renameOrganize, .file), .serialized)
final class MoveRootTests: BinTestCase {
    private var readOnly: URL?

    deinit {
        if let readOnly {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: readOnly.path)
        }
    }

    private func folder(_ path: String) throws -> URL {
        let url = bin.appendingPathComponent(path, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func theCommonAncestorIsTheDeepestFolderHoldingEverySource() {
        let a = bin.appendingPathComponent("a")

        #expect(MoveRoot.commonAncestor(of: [a.appendingPathComponent("1"), a.appendingPathComponent("b/2")]).path == a.standardizedFileURL.path)
        #expect(MoveRoot.commonAncestor(of: [a.appendingPathComponent("1"), bin.appendingPathComponent("c/2")]).path == bin.standardizedFileURL.path)
    }

    @Test func aPhotosLibraryAndAFolderInsideItAreRefused() throws {
        let library = try folder("Photos Library.photoslibrary")
        let inside = try folder("Photos Library.photoslibrary/originals")

        #expect(throws: MoveRootError.insidePackage(library.standardizedFileURL)) { try MoveRoot(validating: library) }
        #expect(throws: MoveRootError.insidePackage(inside.standardizedFileURL)) { try MoveRoot(validating: inside) }
    }

    @Test func aFolderThatCannotBeWrittenIsRefusedAndAWritableOneAccepted() throws {
        let locked = try folder("locked")
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: locked.path)
        readOnly = locked

        #expect(throws: MoveRootError.notWritable(locked.standardizedFileURL)) { try MoveRoot(validating: locked) }

        let root = try MoveRoot(validating: try folder("open"))
        #expect(root.volume != nil)
        #expect(root.isCaseSensitive == BatchOutputClaims.volumeIsCaseSensitive(at: bin))
    }

    @Test func aRootReadsItsVolumesFreeSpaceAndCloning() throws {
        let open = try folder("open")
        let root = try MoveRoot(validating: open)
        let cloning = try open.resourceValues(forKeys: [.volumeSupportsFileCloningKey]).volumeSupportsFileCloning

        #expect(root.availableCapacity.map { $0 > 0 } == true)
        #expect(root.supportsCloning == cloning)
    }

    /// Free space moves between reads; the root is the same folder.
    @Test func twoReadsOfOneFolderAreEqual() throws {
        let open = try folder("open")
        let first = try MoveRoot(validating: open)
        try Data(count: 1_048_576).write(to: open.appendingPathComponent("filler"))

        #expect(try MoveRoot(validating: open) == first)
    }

    @Test func aCopyNeedsTheBytesOfFilesTheRootCannotClone() {
        let here = URL(fileURLWithPath: "/", isDirectory: true)
        let there = URL(fileURLWithPath: "/Volumes/Other", isDirectory: true)
        let sources: [(size: UInt64?, volume: URL?)] = [(10, here), (20, there), (5, nil), (nil, there)]

        #expect(MoveRoot.bytesToCopy(sources, rootVolume: here, rootClones: true) == 25)
        #expect(MoveRoot.bytesToCopy(sources, rootVolume: here, rootClones: false) == 35)
    }

    @Test func twoFoldersInTheBinReadAsOneVolume() throws {
        let a = try #require(MoveRoot.volume(of: try folder("a")))

        #expect(MoveRoot.volume(of: try folder("b/c")) == a)
    }
}
