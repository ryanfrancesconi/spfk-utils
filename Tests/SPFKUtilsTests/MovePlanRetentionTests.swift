// Copyright Ryan Francesconi. All Rights Reserved.

import AVFoundation
import Foundation
import ImageIO
import SPFKBase
import SPFKFileSystem
import SPFKTesting
import Testing
import UniformTypeIdentifiers

@testable import SPFKUtils

/// A rename of a Live Photo keeps nothing per file: the identifier reads, the listing, the plan and
/// the move, two thousand times over.
@Suite(.tags(.renameOrganize, .slow, .file), .serialized)
final class MovePlanRetentionTests: BinTestCase {
    /// `sharksandwich.heic`, the largest bundled HEIC, rewritten with a Live Photo identifier, and
    /// `sample.mov` exported with the same one.
    private func makeLivePhoto() async throws -> (still: URL, movie: URL) {
        let identifier = UUID().uuidString
        let still = bin.appendingPathComponent("template.HEIC")
        let movie = bin.appendingPathComponent("template.MOV")

        let source = try #require(CGImageSourceCreateWithURL(TestBundleResources.shared.sharksandwich_heic as CFURL, nil))
        let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        let destination = try #require(CGImageDestinationCreateWithURL(still as CFURL, UTType.heic.identifier as CFString, 1, nil))
        let properties: [CFString: Any] = [kCGImagePropertyMakerAppleDictionary: ["17": identifier]]
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        try #require(CGImageDestinationFinalize(destination))

        let item = AVMutableMetadataItem()
        item.identifier = .quickTimeMetadataContentIdentifier
        item.value = identifier as NSString
        item.dataType = kCMMetadataBaseDataType_UTF8 as String

        let session = try #require(AVAssetExportSession(asset: AVURLAsset(url: TestBundleResources.shared.sample_mov), presetName: AVAssetExportPresetPassthrough))
        session.metadata = [item]

        guard #available(macOS 15, iOS 18, *) else { throw CocoaError(.featureUnsupported) }
        try await session.export(to: movie, as: .mov)

        return (still, movie)
    }

    @Test func renamingLivePhotosRetainsNothingPerFile() async throws {
        let (still, movie) = try await makeLivePhoto()
        let bin = bin

        try #require(await FileCompanions.resolve([still])[still] == [movie])

        let grown = try await retainedMemoryMB(warmUp: 200, measured: 2000, width: 8) { index in
            let folder = bin.appendingPathComponent("item-\(index)", isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: folder) }

            let photo = folder.appendingPathComponent("IMG_1234.HEIC")
            try FileManager.default.copyItem(at: still, to: photo)
            try FileManager.default.copyItem(at: movie, to: folder.appendingPathComponent("IMG_1234.MOV"))

            let companions = await FileCompanions.resolve([photo])

            let plan = MovePlanBuilder.build(
                inputs: [MovePlanInput(url: photo, values: NameTemplate.urlValues(for: photo))],
                companions: companions,
                template: NameTemplate("Trip_{seq:3}"),
                listing: FolderListing.reading([folder])
            )

            let moves = try await MainActor.run { try FileCommands.move(plan, rollingBackOnFailure: true) }

            guard moves.companions.count == 1 else { throw CocoaError(.fileWriteUnknown) }
        }

        #expect(grown < 50, "grew \(Int(grown)) MB over 2000 renames")
    }
}
