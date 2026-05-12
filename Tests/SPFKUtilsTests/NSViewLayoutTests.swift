// Copyright Ryan Francesconi. All Rights Reserved.

#if os(macOS)
    import AppKit
    import Foundation
    import SPFKBase
    import Testing

    @testable import SPFKUtils

    @Suite
    @MainActor
    final class NSViewLayoutTests {
        // MARK: - alignVertical

        @Test func alignVerticalCentersWithReferenceFrame() {
            let view = NSView(frame: NSRect(x: 10, y: 0, width: 20, height: 10))

            let reference = NSRect(x: 50, y: 20, width: 100, height: 40)
            view.alignVertical(with: reference)

            // Reference midY = 20 + 20 = 40, view half-height = 5, expected y = 35
            #expect(view.frame.origin.y == 35)
            // x should be unchanged
            #expect(view.frame.origin.x == 10)
        }

        @Test func alignVerticalWithSameSizeFrame() {
            let view = NSView(frame: NSRect(x: 0, y: 0, width: 30, height: 30))

            let reference = NSRect(x: 10, y: 10, width: 30, height: 30)
            view.alignVertical(with: reference)

            #expect(view.frame.origin.y == 10)
        }

        @Test func alignVerticalWithZeroHeightView() {
            let view = NSView(frame: NSRect(x: 5, y: 0, width: 20, height: 0))

            let reference = NSRect(x: 0, y: 10, width: 50, height: 20)
            view.alignVertical(with: reference)

            #expect(view.frame.origin.y == 20)
        }

        // MARK: - alignHorizontal

        @Test func alignHorizontalCentersWithReferenceFrame() {
            let view = NSView(frame: NSRect(x: 0, y: 10, width: 20, height: 10))

            let reference = NSRect(x: 50, y: 0, width: 100, height: 40)
            view.alignHorizontal(with: reference)

            // Reference midX = 50 + 50 = 100, view half-width = 10, expected x = 90
            #expect(view.frame.origin.x == 90)
            // y should be unchanged
            #expect(view.frame.origin.y == 10)
        }

        @Test func alignHorizontalWithSameSizeFrame() {
            let view = NSView(frame: NSRect(x: 0, y: 0, width: 40, height: 20))

            let reference = NSRect(x: 20, y: 5, width: 40, height: 20)
            view.alignHorizontal(with: reference)

            #expect(view.frame.origin.x == 20)
        }

        // MARK: - centerInSuperview

        @Test func centerInSuperview() {
            let parent = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
            let child = NSView(frame: NSRect(x: 0, y: 0, width: 40, height: 20))
            parent.addSubview(child)

            child.centerInSuperview()

            #expect(child.frame.origin.x == 80)
            #expect(child.frame.origin.y == 40)
        }

        @Test func centerInSuperviewWithoutParentIsNoop() {
            let view = NSView(frame: NSRect(x: 15, y: 25, width: 10, height: 10))

            view.centerInSuperview()

            #expect(view.frame.origin.x == 15)
            #expect(view.frame.origin.y == 25)
        }

        // MARK: - centerVerticalInSuperview

        @Test func centerVerticalInSuperview() {
            let parent = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
            let child = NSView(frame: NSRect(x: 30, y: 0, width: 40, height: 20))
            parent.addSubview(child)

            child.centerVerticalInSuperview()

            #expect(child.frame.origin.x == 30)
            #expect(child.frame.origin.y == 40)
        }

        // MARK: - centerHorizontalInSuperview

        @Test func centerHorizontalInSuperview() {
            let parent = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
            let child = NSView(frame: NSRect(x: 0, y: 15, width: 40, height: 20))
            parent.addSubview(child)

            child.centerHorizontalInSuperview()

            #expect(child.frame.origin.x == 80)
            #expect(child.frame.origin.y == 15)
        }

        @Test func centerHorizontalOddWidthSubpixel() {
            let parent = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
            let child = NSView(frame: NSRect(x: 0, y: 10, width: 41, height: 20))
            parent.addSubview(child)

            child.centerHorizontalInSuperview()

            // (200/2) - (41/2) = 79.5 — NSView version does not snap
            #expect(child.frame.origin.x == 79.5)
        }

        // MARK: - Consistency between NSView and CALayer

        @Test func alignVerticalMatchesBetweenViewAndLayer() {
            let view = NSView(frame: NSRect(x: 5, y: 0, width: 30, height: 14))
            let layer = CALayer()
            layer.frame = CGRect(x: 5, y: 0, width: 30, height: 14)

            let reference = NSRect(x: 10, y: 20, width: 80, height: 50)

            view.alignVertical(with: reference)
            layer.alignVertical(with: reference)

            #expect(view.frame.origin.y == layer.frame.origin.y)
        }

        @Test func alignHorizontalMatchesBetweenViewAndLayer() {
            let view = NSView(frame: NSRect(x: 0, y: 5, width: 24, height: 10))
            let layer = CALayer()
            layer.frame = CGRect(x: 0, y: 5, width: 24, height: 10)

            let reference = NSRect(x: 30, y: 0, width: 100, height: 60)

            view.alignHorizontal(with: reference)
            layer.alignHorizontal(with: reference)

            #expect(view.frame.origin.x == layer.frame.origin.x)
        }
    }
#endif
