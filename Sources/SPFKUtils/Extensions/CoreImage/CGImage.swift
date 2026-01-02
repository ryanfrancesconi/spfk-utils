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

extension CGColor {
    public static func from(hexColor: HexColor) -> CGColor? {
        from(hexString: hexColor.hexString)
    }

    public static func from(hexString: String) -> CGColor? {
        let hexColor = hexString.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0

        guard scanner.scanHexInt64(&hexNumber) else { return nil }

        let red = CGFloat((hexNumber & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hexNumber & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat((hexNumber & 0x0000FF) >> 0) / 255.0

        return self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }

    public func toHex(alpha: Bool = false) -> String? {
        guard let components,
              components.count >= 3
        else {
            return nil
        }

        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        if alpha {
            return String(
                format: "%02lX%02lX%02lX%02lX",
                lroundf(r * 255),
                lroundf(g * 255),
                lroundf(b * 255),
                lroundf(a * 255)
            )
        } else {
            return String(
                format: "%02lX%02lX%02lX",
                lroundf(r * 255),
                lroundf(g * 255),
                lroundf(b * 255)
            )
        }
    }
}
