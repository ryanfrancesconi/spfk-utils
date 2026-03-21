// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import QuartzCore

extension CALayer {
    // MARK: - Positioning relative to superlayer edges

    /// Positions the layer's right edge `margin` points from the superlayer's right edge.
    public func alignRight(margin: CGFloat = 0) {
        guard let superlayer else { return }
        frame.origin.x = superlayer.frame.width - frame.width - margin
    }

    /// Positions the layer's bottom edge `margin` points from the superlayer's bottom edge.
    public func alignBottom(margin: CGFloat = 0) {
        guard let superlayer else { return }
        frame.origin.y = superlayer.frame.height - frame.height - margin
    }

    // MARK: - Positioning relative to sibling layers

    /// Positions this layer to the right of `sibling` with the given spacing.
    /// Only sets `frame.origin.x`; the y position is unchanged.
    public func placeRight(of sibling: CALayer, spacing: CGFloat = 0) {
        frame.origin.x = sibling.frame.maxX + spacing
    }

    /// Positions this layer below `sibling` with the given spacing.
    /// In flipped coordinates (top-down), "below" means a larger y value.
    /// Only sets `frame.origin.y`; the x position is unchanged.
    public func placeBelow(_ sibling: CALayer, spacing: CGFloat = 0) {
        frame.origin.y = sibling.frame.maxY + spacing
    }

    // MARK: - Fill sizing

    /// Sets the layer's width to fill its superlayer, inset by `left` and `right` margins.
    /// Only changes `frame.size.width`; origin and height are unchanged.
    public func fillWidth(left: CGFloat = 0, right: CGFloat = 0) {
        guard let superlayer else { return }
        frame.size.width = superlayer.frame.width - left - right
    }

    /// Sets the layer's width to span from its current `frame.origin.x` to the
    /// left edge of `sibling`, with `spacing` points of gap.
    /// Only changes `frame.size.width`.
    public func fillWidth(before sibling: CALayer, spacing: CGFloat = 0) {
        frame.size.width = sibling.frame.minX - frame.origin.x - spacing
    }

    /// Sets the layer's height to fill its superlayer, inset by `top` and `bottom` margins.
    /// Only changes `frame.size.height`; origin and width are unchanged.
    public func fillHeight(top: CGFloat = 0, bottom: CGFloat = 0) {
        guard let superlayer else { return }
        frame.size.height = superlayer.frame.height - top - bottom
    }
}
