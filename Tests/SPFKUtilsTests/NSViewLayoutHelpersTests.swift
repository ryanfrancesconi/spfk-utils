// Copyright Ryan Francesconi. All Rights Reserved.

import AppKit
import Foundation
import SPFKBase
import Testing

@testable import SPFKUtils

@Suite
@MainActor
final class NSViewLayoutHelpersTests {
    // MARK: - alignRight

    @Test func alignRightDefaultMargin() {
        let parent = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
        let child = NSView(frame: NSRect(x: 0, y: 10, width: 40, height: 20))
        parent.addSubview(child)

        child.alignRight()

        #expect(child.frame.origin.x == 160)
        #expect(child.frame.origin.y == 10)
    }

    @Test func alignRightWithMargin() {
        let parent = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
        let child = NSView(frame: NSRect(x: 0, y: 10, width: 40, height: 20))
        parent.addSubview(child)

        child.alignRight(margin: 5)

        #expect(child.frame.origin.x == 155)
    }

    @Test func alignRightWithoutSuperviewIsNoop() {
        let view = NSView(frame: NSRect(x: 10, y: 10, width: 40, height: 20))
        view.alignRight(margin: 5)
        #expect(view.frame.origin.x == 10)
    }

    // MARK: - alignBottom

    @Test func alignBottomDefaultMargin() {
        let parent = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
        let child = NSView(frame: NSRect(x: 10, y: 0, width: 40, height: 20))
        parent.addSubview(child)

        child.alignBottom()

        #expect(child.frame.origin.y == 80)
        #expect(child.frame.origin.x == 10)
    }

    @Test func alignBottomWithMargin() {
        let parent = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
        let child = NSView(frame: NSRect(x: 10, y: 0, width: 40, height: 20))
        parent.addSubview(child)

        child.alignBottom(margin: 8)

        #expect(child.frame.origin.y == 72)
    }

    // MARK: - placeRight

    @Test func placeRightOfSibling() {
        let parent = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
        let sibling = NSView(frame: NSRect(x: 20, y: 10, width: 50, height: 20))
        let child = NSView(frame: NSRect(x: 0, y: 15, width: 30, height: 20))
        parent.addSubview(sibling)
        parent.addSubview(child)

        child.placeRight(of: sibling, spacing: 8)

        // sibling.maxX = 70, + 8 = 78
        #expect(child.frame.origin.x == 78)
        #expect(child.frame.origin.y == 15)
    }

    @Test func placeRightZeroSpacing() {
        let sibling = NSView(frame: NSRect(x: 10, y: 0, width: 40, height: 20))
        let child = NSView(frame: NSRect(x: 0, y: 0, width: 30, height: 20))

        child.placeRight(of: sibling)

        #expect(child.frame.origin.x == 50)
    }

    // MARK: - placeBelow

    @Test func placeBelowSibling() {
        let parent = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 300))
        let sibling = NSView(frame: NSRect(x: 10, y: 20, width: 50, height: 30))
        let child = NSView(frame: NSRect(x: 5, y: 0, width: 40, height: 20))
        parent.addSubview(sibling)
        parent.addSubview(child)

        child.placeBelow(sibling, spacing: 10)

        // sibling.maxY = 50, + 10 = 60
        #expect(child.frame.origin.y == 60)
        #expect(child.frame.origin.x == 5)
    }

    // MARK: - fillWidth

    @Test func fillWidthDefaultInsets() {
        let parent = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
        let child = NSView(frame: NSRect(x: 0, y: 0, width: 50, height: 20))
        parent.addSubview(child)

        child.fillWidth()

        #expect(child.frame.size.width == 200)
    }

    @Test func fillWidthWithInsets() {
        let parent = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
        let child = NSView(frame: NSRect(x: 10, y: 0, width: 50, height: 20))
        parent.addSubview(child)

        child.fillWidth(left: 10, right: 15)

        #expect(child.frame.size.width == 175)
    }

    @Test func fillWidthWithoutSuperviewIsNoop() {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 50, height: 20))
        view.fillWidth(left: 10, right: 10)
        #expect(view.frame.size.width == 50)
    }

    // MARK: - fillWidth(before:)

    @Test func fillWidthBeforeSibling() {
        let parent = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
        let child = NSView(frame: NSRect(x: 10, y: 0, width: 50, height: 20))
        let sibling = NSView(frame: NSRect(x: 200, y: 0, width: 80, height: 20))
        parent.addSubview(child)
        parent.addSubview(sibling)

        child.fillWidth(before: sibling, spacing: 5)

        // sibling.minX = 200, child.origin.x = 10, spacing = 5 → 200 - 10 - 5 = 185
        #expect(child.frame.size.width == 185)
    }

    // MARK: - fillHeight

    @Test func fillHeightDefaultInsets() {
        let parent = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
        let child = NSView(frame: NSRect(x: 0, y: 0, width: 50, height: 20))
        parent.addSubview(child)

        child.fillHeight()

        #expect(child.frame.size.height == 100)
    }

    @Test func fillHeightWithInsets() {
        let parent = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
        let child = NSView(frame: NSRect(x: 0, y: 0, width: 50, height: 20))
        parent.addSubview(child)

        child.fillHeight(top: 10, bottom: 5)

        #expect(child.frame.size.height == 85)
    }
}
