// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import AppKit

    extension NSView {
        // MARK: - Positioning relative to superview edges

        /// Positions the view's right edge `margin` points from the superview's right edge.
        public func alignRight(margin: CGFloat = 0) {
            guard let superview else { return }
            frame.origin.x = superview.frame.width - frame.width - margin
        }

        /// Positions the view's bottom edge `margin` points from the superview's bottom edge.
        /// In a flipped coordinate system this aligns to the visual bottom.
        public func alignBottom(margin: CGFloat = 0) {
            guard let superview else { return }
            frame.origin.y = superview.frame.height - frame.height - margin
        }

        // MARK: - Positioning relative to sibling views

        /// Positions this view to the right of `sibling` with the given spacing.
        /// Only sets `frame.origin.x`; the y position is unchanged.
        public func placeRight(of sibling: NSView, spacing: CGFloat = 0) {
            frame.origin.x = sibling.frame.maxX + spacing
        }

        /// Positions this view below `sibling` with the given spacing.
        /// In flipped coordinates (top-down), "below" means a larger y value.
        /// Only sets `frame.origin.y`; the x position is unchanged.
        public func placeBelow(_ sibling: NSView, spacing: CGFloat = 0) {
            frame.origin.y = sibling.frame.maxY + spacing
        }

        // MARK: - Fill sizing

        /// Sets the view's width to fill its superview, inset by `left` and `right` margins.
        /// Only changes `frame.size.width`; origin and height are unchanged.
        public func fillWidth(left: CGFloat = 0, right: CGFloat = 0) {
            guard let superview else { return }
            frame.size.width = superview.frame.width - left - right
        }

        /// Sets the view's width to span from its current `frame.origin.x` to the
        /// left edge of `sibling`, with `spacing` points of gap.
        /// Only changes `frame.size.width`.
        public func fillWidth(before sibling: NSView, spacing: CGFloat = 0) {
            frame.size.width = sibling.frame.minX - frame.origin.x - spacing
        }

        /// Sets the view's height to fill its superview, inset by `top` and `bottom` margins.
        /// Only changes `frame.size.height`; origin and width are unchanged.
        public func fillHeight(top: CGFloat = 0, bottom: CGFloat = 0) {
            guard let superview else { return }
            frame.size.height = superview.frame.height - top - bottom
        }
    }
#endif
