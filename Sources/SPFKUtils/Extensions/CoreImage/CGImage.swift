// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import CoreGraphics
import CoreImage
import Foundation

extension CGImage {
    /// Fast content fingerprint using image dimensions and the first 256 bytes of raw pixel data.
    /// Handles the common case of identical album artwork embedded in multiple tracks.
    public var fingerprint: Int? {
        var hasher = Hasher()
        hasher.combine(width)
        hasher.combine(height)

        guard let cfData = dataProvider?.data else { return nil }

        let data = cfData as Data
        hasher.combine(data.prefix(256))

        return hasher.finalize()
    }

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
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: binfo
        ) else {
            return nil
        }

        context.interpolationQuality = .high

        context.draw(
            self,
            in: CGRect(x: 0, y: 0, width: width, height: height)
        )

        return context.makeImage()
    }

    /// Compares the raw pixel data of two images.
    ///
    /// Returns `true` when both images have the same dimensions and their
    /// `CGDataProvider` byte sequences are identical. Returns `false` if
    /// dimensions differ or pixel data cannot be read from either image.
    public func hasEqualPixelData(_ other: CGImage) -> Bool {
        guard width == other.width, height == other.height else {
            return false
        }

        guard let selfData = dataProvider?.data as Data?,
              let otherData = other.dataProvider?.data as Data?
        else {
            return false
        }

        return selfData == otherData
    }

    public static func create(from data: Data) throws -> CGImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw NSError(description: "CGImageSourceCreateWithData failed to create source")
        }

        // Get the first image from the source
        guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw NSError(description: "CGImageSourceCreateImageAtIndex 0 failed to create cgImage")
        }

        return cgImage
    }

    public static func contentsOf(url: URL) throws -> CGImage {
        try create(from: Data(contentsOf: url))
    }
}

