// Copyright Ryan Francesconi. All Rights Reserved.

import CoreGraphics
import Foundation
import SPFKBase
import SPFKImage
import SPFKTesting
import Testing

@testable import SPFKUtils

/// Thumbnail reads run concurrently, and answer exactly what serial reads do.
@Suite(.tags(.file, .thumbnailFill))
final class ImageDataStoreConcurrentReadTests: BinTestCase {
    private func image(shade: Int) throws -> CGImage {
        let context = try #require(CGContext(
            data: nil, width: 16, height: 16, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(red: CGFloat(shade) / 64, green: 0.5, blue: 0, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: 16, height: 16))
        return try #require(context.makeImage())
    }

    @Test func concurrentThumbnailFetchesMatchSerialOnes() async throws {
        deleteBinOnExit = true
        let store = try ImageDataStore(inDirectory: bin)

        // Every fourth URL has nothing cached, so misses are interleaved with hits.
        let urls = (0 ..< 64).map { URL(fileURLWithPath: "/Volume/Images/\($0).png") }
        for (i, url) in urls.enumerated() where i % 4 != 0 {
            try await store.insert(.thumbnail, cgImage: image(shade: i), for: url)
        }

        var serial: [URL: Int?] = [:]
        for url in urls {
            serial.updateValue(await store.fetch(.thumbnail, for: url).map { $0.fingerprint ?? -1 }, forKey: url)
        }

        let concurrent = await withTaskGroup(of: (URL, Int?).self) { group in
            for url in urls {
                group.addTask { (url, await store.fetch(.thumbnail, for: url).map { $0.fingerprint ?? -1 }) }
            }
            var result: [URL: Int?] = [:]
            for await (url, fingerprint) in group { result.updateValue(fingerprint, forKey: url) }
            return result
        }

        #expect(concurrent == serial)
        #expect(serial.values.filter { $0 == nil }.count == 16)
    }
}
