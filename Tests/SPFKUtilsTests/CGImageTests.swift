// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
    import CoreGraphics
    import Foundation
import SPFKBase
    import SPFKTesting
    import Testing
    import UniformTypeIdentifiers

    @testable import SPFKUtils

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

        @Test func scale() async throws {
            deleteBinOnExit = false
            let nsImage = try #require(TestBundleResources.shared.cowbell_wav.bestImageRepresentation)
            let cgImage = try #require(nsImage.cgImage)

            #expect(cgImage.width == 1024)
            #expect(cgImage.height == 1024)

            let scaledImage = try #require(cgImage.scaled(to: CGSize(equal: 32)))

            #expect(scaledImage.width == 32)
            #expect(scaledImage.height == 32)

            try scaledImage.pngRepresentation?.write(to: bin.appendingPathComponent("test.png"))
        }
    }
#endif
