// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import QuartzCore
import SPFKBase

extension CALayer {
    @objc
    open func opacityFadeIn(_ duration: Double = 0.3) {
        let anim = CABasicAnimation()
        anim.fromValue = 0.0
        anim.toValue = 1.0
        anim.duration = duration
        add(anim, forKey: "opacity")
        opacity = 1.0
    }

    @objc
    open func opacityFadeOut(_ duration: Double = 0.3) {
        let anim = CABasicAnimation()
        anim.fromValue = 1.0
        anim.toValue = 0.0
        anim.duration = duration
        add(anim, forKey: "opacity")
        opacity = 0.0
    }

    @objc
    open func opacityPulse(duration: TimeInterval = 2) {
        let anim = CABasicAnimation()
        anim.fromValue = 1.0
        anim.toValue = 0.3
        anim.autoreverses = true
        anim.repeatCount = .infinity
        anim.duration = duration
        add(anim, forKey: "opacity")
    }

    public func alignHorizontal(with otherFrame: NSRect) {
        let value = (otherFrame.width / 2) - (frame.width / 2)
        frame.origin.x = otherFrame.origin.x + value
    }

    public func alignVertical(with otherFrame: NSRect) {
        let value = (otherFrame.height / 2) - (frame.height / 2)
        frame.origin.y = otherFrame.origin.y + value
    }

    public func centerInSuperlayer() {
        guard let superlayer else { return }

        frame.origin = CGPoint(
            x: (superlayer.frame.width / 2) - (frame.width / 2),
            y: (superlayer.frame.height / 2) - (frame.height / 2)
        )
    }

    public func centerVerticalInSuperlayer() {
        guard let superlayer else { return }

        frame.origin = CGPoint(
            x: frame.origin.x,
            y: (superlayer.frame.height / 2) - (frame.height / 2)
        )
    }

    public func centerHorizontalInSuperlayer(allowSubpixelValues: Bool = false) {
        guard let superlayer else { return }

        let value = CGPoint(
            x: (superlayer.frame.width / 2) - (frame.width / 2),
            y: frame.origin.y
        )

        frame.origin = allowSubpixelValues ? value : CGPoint(x: value.x.int, y: value.y.int)
    }

    @objc
    open func setFrameWidth(_ width: CGFloat) {
        let size = CGSize(width: width, height: frame.height)
        setFrameSize(size)
    }

    @objc
    open func setFrameHeight(_ height: CGFloat) {
        setFrameSize(CGSize(width: frame.width, height: height))
    }

    @objc
    open func setFrameSize(_ newSize: CGSize) {
        guard frame.size != newSize else { return }
        frame.size = newSize
    }

    @objc
    open func setFrameOrigin(_ newPoint: CGPoint) {
        guard frame.origin != newPoint else { return }
        frame.origin = newPoint
    }

    @objc open func updateRecursive(contentsScale: CGFloat) {
        self.contentsScale = contentsScale

        sublayers?.forEach {
            $0.updateRecursive(contentsScale: contentsScale)
        }
    }
}

#if os(macOS)
    import AppKit

    extension CALayer {
        public func rasterize(
            at size: CGSize? = nil,
            shouldAntialias: Bool = true,
            imageInterpolation: NSImageInterpolation = .default
        ) -> CGImage? {
            let width = Int(size?.width ?? frame.width)
            let height = Int(size?.height ?? frame.height)

            guard let imageRep = NSBitmapImageRep(
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
            ),

                let context = NSGraphicsContext(bitmapImageRep: imageRep)
            else {
                Log.error("Failed to make context")
                return nil
            }

            context.imageInterpolation = imageInterpolation
            context.shouldAntialias = shouldAntialias

            let cgContext = context.cgContext

            render(in: cgContext)

            return cgContext.makeImage()
        }
    }
#endif
