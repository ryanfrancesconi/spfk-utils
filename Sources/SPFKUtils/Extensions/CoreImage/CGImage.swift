// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import CoreGraphics
import CoreImage
import Foundation

extension CGImage {
    public func scaled(to size: CGSize) -> CGImage? {
        let width: Int = Int(size.width)
        let height: Int = Int(size.height)

        var binfo = bitmapInfo
        binfo.pixelFormat = .packed
        binfo.byteOrder = .orderDefault
        binfo.alpha = .premultipliedLast

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: binfo
        ) else {
            return nil
        }

        context.interpolationQuality = .high

        // [Internal] Thread running at User-initiated quality-of-service class waiting on a thread without a QoS class specified (base priority 0). Investigate ways to avoid priority inversions
        context.draw(
            self,
            in: CGRect(x: 0, y: 0, width: width, height: height)
        )

        return context.makeImage()
    }

    public static func createJPEG(from data: Data) throws -> CGImage {
        guard let dataProvider = CGDataProvider(data: data as CFData) else {
            throw NSError(description: "Failed to create CGDataProvider")
        }

        guard let cgImage = CGImage(
            jpegDataProviderSource: dataProvider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else {
            throw NSError(description: "Failed to create CGImage")
        }

        return cgImage
    }
}
