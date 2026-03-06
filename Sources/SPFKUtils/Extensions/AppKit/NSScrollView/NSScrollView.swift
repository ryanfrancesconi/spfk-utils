// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import CoreGraphics

public enum ScrollAlignment {
    case left
    case center
}

public enum ScrollToBehavior {
    case visible
    case centerIfOutOfView
    case centerAlways
}

extension NSScrollView {
    public func updateHorizontalScroll(
        position x: CGFloat,
        alignment: ScrollAlignment = .center,
        onlyIfNeeded: Bool = true
    ) {
        let visibleWidth = documentVisibleRect.width
        let visibleOrigin = documentVisibleRect.origin

        if onlyIfNeeded,
           x > visibleOrigin.x, x < visibleOrigin.x + visibleWidth,
           x < visibleOrigin.x + visibleWidth {
            // Log.debug("In view, no scroll needed")
            return
        }

        let widthOffset: CGFloat = alignment == .center ? (visibleWidth / 2) : 0
        let y = contentView.bounds.origin.y
        let adjustedX = x - widthOffset
        let origin = NSPoint(x: adjustedX, y: y)

        contentView.scroll(origin)
    }
}

extension NSScrollView {
    public static func basicScrollView() -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.autohidesScrollers = true
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.usesPredominantAxisScrolling = true
        scrollView.allowsMagnification = false
        scrollView.horizontalScrollElasticity = .none
        scrollView.verticalScrollElasticity = .none
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        return scrollView
    }
}
#endif
