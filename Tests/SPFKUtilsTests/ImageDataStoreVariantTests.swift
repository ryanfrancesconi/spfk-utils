// Copyright Ryan Francesconi. All Rights Reserved.

import CoreGraphics
import Foundation
import SPFKBase
import SPFKImage
import SPFKTesting
import Testing
import UniformTypeIdentifiers

@testable import SPFKUtils

/// Variant thumbnails live beside a file's plain one and follow it through delete, rekey and prune.
@MainActor
@Suite(.tags(.file))
final class ImageDataStoreVariantTests: BinTestCase {
    private func image(red: CGFloat) throws -> CGImage {
        let context = try #require(CGContext(
            data: nil, width: 32, height: 32, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(red: red, green: 0, blue: 0, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: 32, height: 32))
        let raw = try #require(context.makeImage())
        return try CGImage.create(from: raw.dataRepresentation(utType: .png))
    }

    private func makeStore() throws -> ImageDataStore {
        deleteBinOnExit = true
        return try ImageDataStore(inDirectory: bin)
    }

    private let url = URL(fileURLWithPath: "/Pictures/a.raf")
    private let moved = URL(fileURLWithPath: "/Moved/a.raf")

    /// The plain entry and two variants, each a different image, all for `url`.
    private func insertThree(_ store: ImageDataStore, for url: URL) async throws -> (CachedImageType, CachedImageType) {
        let a = try CachedImageType.thumbnailVariant(CachedImageVariant("a1b2"))
        let b = try CachedImageType.thumbnailVariant(CachedImageVariant("C3d4"))

        try await store.insert(.thumbnail, cgImage: image(red: 0.2), for: url)
        try await store.insert(a, cgImage: image(red: 0.5), for: url)
        try await store.insert(b, cgImage: image(red: 0.9), for: url)

        return (a, b)
    }

    private func red(_ image: CGImage?) throws -> Double {
        try #require(image?.averageRed)
    }

    @Test func variantsAndThePlainEntryAreIndependent() async throws {
        let store = try makeStore()
        let (a, b) = try await insertThree(store, for: url)

        let plain = try await red(store.fetch(.thumbnail, for: url))
        let first = try await red(store.fetch(a, for: url))
        let second = try await red(store.fetch(b, for: url))

        #expect(plain < first)
        #expect(first < second)
        #expect(await store.cacheDate(a, for: url) != nil)
        #expect(try await store.fetch(.thumbnailVariant(CachedImageVariant("other")), for: url) == nil)
        #expect(await store.count() == 1)
    }

    @Test func deleteRemovesEveryVariant() async throws {
        let store = try makeStore()
        let (a, b) = try await insertThree(store, for: url)

        await store.delete(url: url)

        #expect(await store.fetch(.thumbnail, for: url) == nil)
        #expect(await store.fetch(a, for: url) == nil)
        #expect(await store.fetch(b, for: url) == nil)
        #expect(await store.cacheDate(a, for: url) == nil)
        #expect(await store.count() == 0)
    }

    @Test func rekeyCarriesEveryVariant() async throws {
        let store = try makeStore()
        let (a, b) = try await insertThree(store, for: url)

        try await store.rekey(from: url, to: moved)

        #expect(await store.fetch(a, for: url) == nil)
        #expect(try await red(store.fetch(.thumbnail, for: moved)) < red(store.fetch(a, for: moved)))
        #expect(try await red(store.fetch(a, for: moved)) < red(store.fetch(b, for: moved)))
    }

    @Test func pruneKeepsALiveFilesVariantsAndRemovesADeadOnes() async throws {
        let store = try makeStore()
        let dead = URL(fileURLWithPath: "/Gone/b.raf")
        let (a, _) = try await insertThree(store, for: url)
        try await store.insert(a, cgImage: image(red: 0.7), for: dead)

        let removed = await store.prune(activeURLs: [url])

        #expect(removed == 1)
        #expect(await store.fetch(a, for: url) != nil)
        #expect(await store.fetch(a, for: dead) == nil)
    }

    /// Two files whose variants have the same pixels share one file, and rewriting one leaves the other.
    @Test func rewritingASharedVariantLeavesTheOtherFilesImage() async throws {
        let store = try makeStore()
        let a = try CachedImageType.thumbnailVariant(CachedImageVariant("abc"))

        try await store.insert(a, cgImage: image(red: 0.5), for: url)
        try await store.insert(a, cgImage: image(red: 0.5), for: moved)
        try await store.insert(a, cgImage: image(red: 0.1), for: url)

        #expect(try await red(store.fetch(a, for: moved)) > red(store.fetch(a, for: url)))
    }
}

struct CachedImageVariantTests {
    @Test(arguments: ["", "a-b", "a/b", "a.b", "é", "a b"])
    func anInvalidVariantNameThrows(name: String) {
        #expect(throws: CachedImageVariantError.invalidName(name)) { try CachedImageVariant(name) }
    }
}

extension CGImage {
    /// Mean red of an RGBA8 render, 0...1.
    fileprivate var averageRed: Double? {
        guard let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return nil }

        let bytes = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        var sum = 0
        for i in 0 ..< width * height { sum += Int(bytes[i * 4]) }
        return Double(sum) / Double(width * height) / 255
    }
}
