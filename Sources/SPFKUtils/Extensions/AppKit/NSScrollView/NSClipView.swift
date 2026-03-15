// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
import AppKit

extension NSClipView {
    /// Default animation duration used for calls to `scroll(to:behavior:)` if not specified when calling the method.
    public static var scrollToAnimationDuration: Double = 0.3

    /// Scroll so that the given rect is scrolled into view.
    ///
    /// - Parameters:
    ///   - rect: The rect within the documentView to make visible.
    ///   - behavior: Scroll behavior.
    ///   - duration: Animation duration for the scroll. If 0.0, scroll will not animate. Uses `scrollToAnimationDuration` value as default if not specified.
    /// - Returns: `true` if scrolling occurred, `false` if no scrolling occurred (`rect` was already visible.)
    @discardableResult
    public func scroll(
        to rect: CGRect,
        behavior: ScrollToBehavior,
        animationDuration duration: Double = scrollToAnimationDuration
    ) -> Bool {
        switch behavior {
        case .visible:
            return scroll(
                toRect: rect,
                animationDuration: duration
            )

        case .centerIfOutOfView:
            return scroll(
                toCenter: rect,
                alwaysCenter: false,
                animationDuration: duration
            )

        case .centerAlways:
            return scroll(
                toCenter: rect,
                alwaysCenter: true,
                animationDuration: duration
            )
        }
    }

    // MARK: - Helpers

    private func scroll(
        toRect rect: CGRect,
        animationDuration duration: Double
    ) -> Bool {
        // unwrap refs
        guard let scrollView = enclosingScrollView,
              let docView = documentView else { return false }
        let clipView = self

        // make a copy of the current origin
        var newOrigin = clipView.documentVisibleRect.origin

        // if we are too far to the right, correct it
        if newOrigin.x > rect.origin.x {
            newOrigin.x = rect.origin.x
        }

        // if we are too far to the left, correct it
        if rect.origin.x > newOrigin.x + clipView.documentVisibleRect.width - rect.width {
            newOrigin.x = rect.origin.x - clipView.documentVisibleRect.width + rect.width
        }

        // if we are too low, correct it
        if newOrigin.y > rect.origin.y {
            newOrigin.y = rect.origin.y
        }

        // if we are too high, correct it
        if rect.origin.y > newOrigin.y + clipView.documentVisibleRect.height - rect.height {
            newOrigin.y = rect.origin.y - clipView.documentVisibleRect.height + rect.height
        }

        // match the new origin to bounds.origin
        newOrigin.x += clipView.bounds.origin.x - clipView.documentVisibleRect.origin.x
        newOrigin.y += clipView.bounds.origin.y - clipView.documentVisibleRect.origin.y

        // clamp X to view edges if necessary
        let minX = docView.bounds.minX + 1
        let maxX = docView.bounds.width - clipView.documentVisibleRect.width

        // clamp Y to view edges if necessary
        let minY = docView.bounds.minY + 1
        let maxY = docView.bounds.height - clipView.documentVisibleRect.height

        newOrigin.x = newOrigin.x.clamped(to: minX ... maxX)
        newOrigin.y = newOrigin.y.clamped(to: minY ... maxY)

        guard newOrigin != clipView.bounds.origin else {
            // no scrolling necessary
            return false
        }

        if duration > 0.0 { // animate
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = duration
            clipView.animator().setBoundsOrigin(newOrigin)
            scrollView.reflectScrolledClipView(clipView)
            NSAnimationContext.endGrouping()

        } else { // no animation
            clipView.setBoundsOrigin(newOrigin)
            scrollView.reflectScrolledClipView(clipView)
        }

        return true
    }

    @discardableResult
    private func scroll(
        toCenter rect: CGRect,
        alwaysCenter: Bool = true,
        animationDuration duration: Double
    ) -> Bool {
        scroll(toCenter: rect.center,
               alwaysCenter: alwaysCenter,
               animationDuration: duration)
    }

    @discardableResult
    private func scroll(
        toCenter point: CGPoint,
        alwaysCenter: Bool = true,
        animationDuration duration: Double
    ) -> Bool {
        guard let scrollView = enclosingScrollView else { return false }
        let clipView = self

        // if point is already in view and alwaysCenter is false, don't scroll
        if !alwaysCenter,
           clipView.documentVisibleRect.contains(point) { return false }

        // make a copy of the current origin
        let newOrigin = CGPoint(x: point.x - (clipView.documentVisibleRect.width / 2),
                                y: point.y - (clipView.documentVisibleRect.height / 2))

        guard newOrigin != clipView.bounds.origin else { return false }

        if duration > 0.0 {
            // animate
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = duration
            clipView.animator().setBoundsOrigin(newOrigin)
            scrollView.reflectScrolledClipView(clipView)
            NSAnimationContext.endGrouping()

        } else {
            // no animation
            clipView.setBoundsOrigin(newOrigin)
            scrollView.reflectScrolledClipView(clipView)
        }

        return true
    }
}
#endif
