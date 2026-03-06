// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit

    extension NSImage {
        public static let application = NSImage(named: NSImage.applicationIconName)
    }

    extension NSImage {
        /// Initializes a new `NSImage` by tinting a template image.
        /// If image is not a template, image is unmodified.
        public convenience init?(templateNamed: NSImage.Name, tint color: NSColor) {
            self.init(named: templateNamed)
            tint(color: color)
        }

        public convenience init(color: NSColor, size: NSSize) {
            self.init(size: size)
            lockFocus()
            color.drawSwatch(in: NSRect(origin: .zero, size: size))
            unlockFocus()
        }
    }

    extension NSImage {
        /// Returns a new `NSImage` by tinting a template image.
        public func tint(color: NSColor) {
            lockFocus()
            color.set()

            let imageBounds = NSRect(origin: .zero, size: size)
            imageBounds.fill(using: .sourceAtop)

            unlockFocus()
            isTemplate = false
        }

        /// Returns a new `NSImage` by tinting a template image.
        public func tinted(color: NSColor) -> NSImage {
            guard let copiedImage = copy() as? NSImage else { return self }

            copiedImage.tint(color: color)

            return copiedImage
        }
    }

    extension NSImage {
        /// Draws the string into this image and returns a new image
        @MainActor public func draw(
            string: String,
            in rect: CGRect,
            color: NSColor,
            alignment: NSTextAlignment = .center,
            font: NSFont = NSFont.smallSystemFont
        ) -> NSImage {
            let targetImage = NSImage(size: size, flipped: true) { (dstRect: CGRect) -> Bool in
                self.draw(in: dstRect)

                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = alignment

                let attributes = [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraphStyle,
                ] as [NSAttributedString.Key: Any]

                string.draw(in: rect, withAttributes: attributes)

                return true
            }

            return targetImage
        }
    }

    extension NSImage {
        /// Returns the height of the current image.
        public var height: CGFloat {
            size.height
        }

        /// Returns the width of the current image.
        public var width: CGFloat {
            size.width
        }

        /// Returns a png representation of the current image.
        public var pngRepresentation: Data? {
            if let tiff = tiffRepresentation,
               let tiffData = NSBitmapImageRep(data: tiff)
            {
                return tiffData.representation(using: .png, properties: [:])
            }
            return nil
        }

        public var jpegRepresentation: Data? {
            if let tiff = tiffRepresentation,
               let tiffData = NSBitmapImageRep(data: tiff)
            {
                return tiffData.representation(using: .jpeg, properties: [:])
            }
            return nil
        }
    }

    extension NSImage {
        ///  Copies the  image and resizes it to the given size.
        ///
        ///  - parameter size: The size of the new image.
        ///
        ///  - returns: The resized copy of the given image.
        public func copy(size: NSSize) -> NSImage? {
            // Create a new rect with given width and height
            let frame = NSMakeRect(0, 0, size.width, size.height)

            // Get the best representation for the given size.
            guard let rep = bestRepresentation(for: frame, context: nil, hints: nil) else {
                return nil
            }

            // Create an empty image with the given size.
            let img = NSImage(size: size)

            // Set the drawing context and make sure to remove the focus before returning.
            img.lockFocus()

            defer { img.unlockFocus() }

            // Draw the new image
            if rep.draw(in: frame) {
                return img
            }

            // Return nil in case something went wrong.
            return nil
        }

        ///  Copies the current image and resizes it to the size of the given NSSize, while
        ///  maintaining the aspect ratio of the original image.
        ///
        ///  - parameter size: The size of the new image.
        ///
        ///  - returns: The resized copy of the given image.
        public func resizeWhileMaintainingAspectRatio(to size: NSSize) -> NSImage? {
            let newSize: NSSize

            let widthRatio = size.width / width
            let heightRatio = size.height / height

            if widthRatio > heightRatio {
                newSize = NSSize(width: floor(width * widthRatio), height: floor(height * widthRatio))

            } else {
                newSize = NSSize(width: floor(width * heightRatio), height: floor(height * heightRatio))
            }

            return copy(size: newSize)
        }

        ///  Copies and crops an image to the supplied size.
        ///
        ///  - parameter size: The size of the new image.
        ///
        ///  - returns: The cropped copy of the given image.
        public func crop(size: NSSize) -> NSImage? {
            // Resize the current image, while preserving the aspect ratio.
            guard let resized = resizeWhileMaintainingAspectRatio(to: size) else {
                return nil
            }
            // Get some points to center the cropping area.
            let x: CGFloat = floor((resized.width - size.width) / 2)
            let y: CGFloat = floor((resized.height - size.height) / 2)

            // Create the cropping frame.
            let croppedFrame = NSRect(x: x, y: y, width: size.width, height: size.height)

            // Get the best representation of the image for the given cropping frame.
            guard let rep = resized.bestRepresentation(for: croppedFrame, context: nil, hints: nil) else {
                return nil
            }

            // Create a new image with the new size
            let img = NSImage(size: size)

            img.lockFocus()

            defer { img.unlockFocus() }

            if rep.draw(
                in: NSRect(x: 0, y: 0, width: size.width, height: size.height),
                from: croppedFrame,
                operation: NSCompositingOperation.copy,
                fraction: 1.0,
                respectFlipped: false,
                hints: [:]
            ) {
                // Return the cropped image.
                return img
            }

            // Return nil in case anything fails.
            return nil
        }

        public func rotate(by degrees: CGFloat) -> NSImage {
            // calculate the bounds for the rotated image
            var imageBounds = NSRect(origin: NSPoint.zero, size: size)

            let boundsPath = NSBezierPath(rect: imageBounds)
            var transform = NSAffineTransform()

            transform.rotate(byDegrees: degrees)
            boundsPath.transform(using: transform as AffineTransform)

            let rotatedBounds = NSRect(origin: NSPoint.zero, size:
                boundsPath.bounds.size)

            let rotatedImage = NSImage(size: rotatedBounds.size)

            // center the image within the rotated bounds
            imageBounds.origin.x = rotatedBounds.midX - imageBounds.midX
            imageBounds.origin.y = rotatedBounds.midY - imageBounds.midY

            // set up the rotation transform
            transform = NSAffineTransform()

            transform.translateX(by: +(rotatedBounds.width / 2), yBy:
                +(rotatedBounds.height / 2))

            transform.rotate(byDegrees: degrees)

            transform.translateX(by: -(rotatedBounds.width / 2), yBy:
                -(rotatedBounds.height / 2))

            // draw the original image, rotated, into the new image
            rotatedImage.lockFocus()
            transform.concat()

            draw(in: imageBounds, from: NSRect.zero, operation: .copy, fraction: 1.0)

            rotatedImage.unlockFocus()

            return rotatedImage
        }

        public func scaled(by value: CGFloat) -> NSImage? {
            // Calculate the new size based on the percentage
            let newWidth = max(16, size.width * value)
            let newHeight = max(16, size.height * value)
            let newSize = NSSize(width: newWidth, height: newHeight)

            return scaled(to: newSize)
        }

        public func scaled(to newSize: CGSize) -> NSImage? {
            guard newSize != .zero else {
                return nil
            }

            // Create a new NSImage with the calculated size
            let scaledImage = NSImage(size: newSize)

            // Lock focus to the new image to draw into it
            scaledImage.lockFocus()

            // Set image interpolation for better quality scaling
            NSGraphicsContext.current?.imageInterpolation = .high

            // Draw the original image into the new image's context
            draw(
                in: NSRect(origin: .zero, size: newSize),
                from: NSRect(origin: .zero, size: size),
                operation: .copy,
                fraction: 1.0
            )

            // Unlock focus
            scaledImage.unlockFocus()
            NSGraphicsContext.current?.imageInterpolation = .default

            return scaledImage
        }

        public func export(to url: URL, filetype: NSBitmapImageRep.FileType) throws {
            guard let data = tiffRepresentation,
                  let rep = NSBitmapImageRep(data: data),
                  let imgData = rep.representation(
                      using: filetype,
                      properties: [.compressionFactor: NSNumber(floatLiteral: 1.0)]
                  )
            else {
                throw NSError(description: "Failed writing image to \(url.path)")
            }

            try imgData.write(to: url)
        }
    }

    extension CGImage {
        public static func contentsOf(
            url: URL,
            priority: TaskPriority = .medium
        ) async throws -> CGImage? {
            let task = Task<CGImage?, Error>(priority: priority) {
                NSImage(contentsOf: url)?.cgImage
            }

            return try await task.value
        }
    }

    extension NSImage {
        @inline(__always) @_disfavoredOverload
        public var cgImage: CGImage? {
            var imageRect = CGRect(width: size.width, height: size.height)

            return cgImage(
                forProposedRect: &imageRect,
                context: nil,
                hints: nil
            )
        }
    }

    extension CGImage {
        @inline(__always) @_disfavoredOverload
        public var nsImage: NSImage? {
            NSImage(
                cgImage: self,
                size: CGSize(width: width, height: height)
            )
        }
    }
#endif
