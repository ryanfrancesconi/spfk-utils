// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import AppKit
    import CoreGraphics
    import Foundation
    import SPFKBase
    import SPFKTesting
    import Testing
    import UniformTypeIdentifiers

    @testable import SPFKUtils

    @Suite
    class CGImageTests: BinTestCase {
        @Test func cgImageDataRoundtrip() async throws {
            let url = TestBundleResources.shared.sharksandwich

            let originalImage = try #require(NSImage(contentsOf: url)?.cgImage)
            Log.debug(originalImage)

            let data = try #require(originalImage.jpegRepresentation)
            let newImage = try #require(NSImage(data: data)?.cgImage)

            Log.debug(newImage)

            #expect(newImage.width == originalImage.width)
            #expect(newImage.height == originalImage.height)
            #expect(newImage.colorSpace == originalImage.colorSpace)
            #expect(newImage.utType == originalImage.utType)
            #expect(newImage.bytesPerRow == originalImage.bytesPerRow)
            #expect(newImage.bitsPerPixel == originalImage.bitsPerPixel)
            #expect(newImage.bitsPerComponent == originalImage.bitsPerComponent)
            #expect(newImage.alphaInfo == originalImage.alphaInfo)
        }

        /// Load the same JPEG twice from disk via NSImage and verify pixel data matches.
        @Test func hasEqualPixelDataWithJPEGLoadedTwice() async throws {
            let url = TestBundleResources.shared.sharksandwich

            let first = try #require(NSImage(contentsOf: url)?.cgImage)
            let second = try #require(NSImage(contentsOf: url)?.cgImage)

            #expect(first.hasEqualPixelData(second))
        }

        /// JPEG re-encoded from memory should NOT match the original pixel data.
        @Test func hasEqualPixelDataFailsAfterReEncoding() async throws {
            let url = TestBundleResources.shared.sharksandwich

            let original = try #require(NSImage(contentsOf: url)?.cgImage)
            let jpegData = try #require(original.jpegRepresentation)
            let reencoded = try #require(NSImage(data: jpegData)?.cgImage)

            // Re-encoding introduces lossy compression artifacts
            #expect(!original.hasEqualPixelData(reencoded))
        }

        /// Load a HEIC image twice and verify pixel data comparison works.
        @Test func hasEqualPixelDataWithHEICLoadedTwice() async throws {
            let url = TestBundleResources.shared.sharksandwich_heic

            let first = try CGImage.contentsOf(url: url)
            let second = try CGImage.contentsOf(url: url)

            let firstData = first.dataProvider?.data as Data?
            let secondData = second.dataProvider?.data as Data?

            Log.debug("first: \(first.width)x\(first.height) bpc:\(first.bitsPerComponent) bpp:\(first.bitsPerPixel) bpr:\(first.bytesPerRow) alpha:\(first.alphaInfo.rawValue)")
            Log.debug("second: \(second.width)x\(second.height) bpc:\(second.bitsPerComponent) bpp:\(second.bitsPerPixel) bpr:\(second.bytesPerRow) alpha:\(second.alphaInfo.rawValue)")
            Log.debug("first data: \(firstData?.count ?? -1) bytes")
            Log.debug("second data: \(secondData?.count ?? -1) bytes")

            #expect(first.hasEqualPixelData(second))
        }

        @Test func scale() async throws {
            deleteBinOnExit = true
            let nsImage = try #require(TestBundleResources.shared.cowbell_wav.bestImageRepresentation)
            let cgImage = try #require(nsImage.cgImage)

            #expect(cgImage.width == 1024)
            #expect(cgImage.height == 1024)

            let scaledImage = try #require(cgImage.scaled(to: CGSize(equal: 32)))

            #expect(scaledImage.width == 32)
            #expect(scaledImage.height == 32)

            try scaledImage.pngRepresentation?.write(to: bin.appendingPathComponent("test.png"))
        }

        // MARK: - Export

        @Test func exportJPEG() async throws {
            deleteBinOnExit = true
            let original = try #require(NSImage(contentsOf: TestBundleResources.shared.sharksandwich)?.cgImage)
            let outputURL = bin.appendingPathComponent("export.jpg")

            try original.export(utType: .jpeg, to: outputURL)

            let data = try Data(contentsOf: outputURL)
            let reloaded = try CGImage.create(from: data)

            #expect(reloaded.width == original.width)
            #expect(reloaded.height == original.height)
        }

        @Test func exportPNG() async throws {
            deleteBinOnExit = true
            let original = try #require(NSImage(contentsOf: TestBundleResources.shared.sharksandwich)?.cgImage)
            let outputURL = bin.appendingPathComponent("export.png")

            try original.export(utType: .png, to: outputURL)

            let data = try Data(contentsOf: outputURL)
            let reloaded = try CGImage.create(from: data)

            #expect(reloaded.width == original.width)
            #expect(reloaded.height == original.height)
        }

        @Test func exportTIFF() async throws {
            deleteBinOnExit = true
            let original = try #require(NSImage(contentsOf: TestBundleResources.shared.sharksandwich)?.cgImage)
            let outputURL = bin.appendingPathComponent("export.tiff")

            try original.export(utType: .tiff, to: outputURL)

            let data = try Data(contentsOf: outputURL)
            let reloaded = try CGImage.create(from: data)

            #expect(reloaded.width == original.width)
            #expect(reloaded.height == original.height)
        }

        @Test func exportUnsupportedTypeThrows() async throws {
            let original = try #require(NSImage(contentsOf: TestBundleResources.shared.sharksandwich)?.cgImage)
            let outputURL = bin.appendingPathComponent("export.gif")

            #expect(throws: (any Error).self) {
                try original.export(utType: .gif, to: outputURL)
            }
        }

        // MARK: - Fingerprint

        @Test func fingerprintIsConsistentForSameImageLoadedTwice() async throws {
            let url = TestBundleResources.shared.sharksandwich

            let first = try #require(NSImage(contentsOf: url)?.cgImage)
            let second = try #require(NSImage(contentsOf: url)?.cgImage)

            let fp1 = try #require(first.fingerprint)
            let fp2 = try #require(second.fingerprint)

            #expect(fp1 == fp2)
        }

        @Test func fingerprintDiffersForDistinctImages() async throws {
            let url = TestBundleResources.shared.sharksandwich

            let original = try #require(NSImage(contentsOf: url)?.cgImage)
            let scaled = try #require(original.scaled(to: CGSize(equal: 64)))

            let fp1 = try #require(original.fingerprint)
            let fp2 = try #require(scaled.fingerprint)

            #expect(fp1 != fp2)
        }

        /// Two covers of the same size whose leading rows match — a white band above the
        /// artwork, which is a common layout — must still fingerprint differently.
        /// `ImageDataStore` hardlinks on fingerprint equality, so a match here serves one
        /// album's artwork for another's.
        @Test func fingerprintDiffersWhenOnlyLaterRowsDiffer() async throws {
            let first = try #require(Self.bandedImage(bodyRed: 1))
            let second = try #require(Self.bandedImage(bodyRed: 0))

            let firstBytes = try #require(first.dataProvider?.data as Data?)
            let secondBytes = try #require(second.dataProvider?.data as Data?)

            // The premise: identical leading bytes, different images.
            #expect(firstBytes.prefix(256) == secondBytes.prefix(256))
            #expect(!first.hasEqualPixelData(second))

            #expect(try #require(first.fingerprint) != #require(second.fingerprint))
        }

        /// A 200x200 image with a white top band and a solid body of the given red component.
        private static func bandedImage(bodyRed: CGFloat) -> CGImage? {
            let side = 200
            guard let context = CGContext(
                data: nil,
                width: side,
                height: side,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return nil }

            context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
            context.fill(CGRect(x: 0, y: 0, width: side, height: side))
            context.setFillColor(red: bodyRed, green: 0, blue: 0, alpha: 1)
            context.fill(CGRect(x: 0, y: 0, width: side, height: side - 20))

            return context.makeImage()
        }

        @Test func exportOverwritesExistingFile() async throws {
            deleteBinOnExit = true
            let original = try #require(NSImage(contentsOf: TestBundleResources.shared.sharksandwich)?.cgImage)
            let outputURL = bin.appendingPathComponent("overwrite.jpg")

            // Write twice — second should overwrite without error
            try original.export(utType: .jpeg, to: outputURL)
            let firstSize = try Data(contentsOf: outputURL).count

            try original.export(utType: .jpeg, to: outputURL)
            let secondSize = try Data(contentsOf: outputURL).count

            #expect(firstSize == secondSize)
        }
    }
#endif
