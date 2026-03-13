// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
    import CoreGraphics
    import SPFKBase

    extension CGMutablePath {
        /// Safely create round rect checking that the rect is big enough to support the cornerRadius
        public static func createRoundRect(in rect: CGRect, cornerRadius: CGFloat) -> CGMutablePath {
            let path = CGMutablePath()

            guard rect.size.width > (cornerRadius * 2), rect.size.height > (cornerRadius * 2) else {
                Log.error("Invalid size passed in", rect, "cornerRadius", cornerRadius)

                path.addRect(rect)
                return path
            }

            path.addRoundedRect(
                in: rect,
                cornerWidth: cornerRadius,
                cornerHeight: cornerRadius
            )

            return path
        }
    }

    extension CGPath {
        public func toCGImage(
            at size: CGSize,
            fillColor: CGColor? = nil,
            strokeColor: CGColor? = nil
        ) throws -> CGImage {
            guard fillColor != nil ||
                strokeColor != nil
            else {
                throw NSError(description: "You must define either stroke or fill color")
            }

            let width = Int(size.width)
            let height = Int(size.height)

            // Log.debug("Creating image at size \(width)x\(height)")

            guard let bitmap = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: width,
                pixelsHigh: height,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: width * 4,
                bitsPerPixel: 32
            ) else {
                throw NSError(description: "Failed to create bitmap image, width: \(width), height: \(height)")
            }

            guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
                throw NSError(description: "Failed to create NSGraphicsContext from bitmap")
            }

            NSGraphicsContext.saveGraphicsState()

            defer {
                NSGraphicsContext.restoreGraphicsState()
            }

            NSGraphicsContext.current = context

            context.shouldAntialias = true
            context.imageInterpolation = .low

            context.cgContext.setAllowsAntialiasing(true)

            if let fillColor {
                context.cgContext.setFillColor(fillColor)
                context.cgContext.addPath(self)
                context.cgContext.fillPath()
            }

            if let strokeColor {
                context.cgContext.setStrokeColor(strokeColor)
                context.cgContext.addPath(self)
                context.cgContext.strokePath()
            }

            context.flushGraphics()

            guard let image = bitmap.cgImage else {
                throw NSError(description: "Failed to convert bitmap to CGImage")
            }

            return image
        }
    }
#endif
