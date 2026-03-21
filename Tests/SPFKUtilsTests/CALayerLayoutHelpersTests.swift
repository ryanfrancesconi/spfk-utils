// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import QuartzCore
import SPFKBase
import Testing

@testable import SPFKUtils

@Suite
@MainActor
final class CALayerLayoutHelpersTests {
    // MARK: - alignRight

    @Test func alignRightDefaultMargin() {
        let parent = CALayer()
        parent.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        let child = CALayer()
        child.frame = CGRect(x: 0, y: 10, width: 40, height: 20)
        parent.addSublayer(child)

        child.alignRight()

        #expect(child.frame.origin.x == 160)
        #expect(child.frame.origin.y == 10)
    }

    @Test func alignRightWithMargin() {
        let parent = CALayer()
        parent.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        let child = CALayer()
        child.frame = CGRect(x: 0, y: 10, width: 40, height: 20)
        parent.addSublayer(child)

        child.alignRight(margin: 5)

        #expect(child.frame.origin.x == 155)
    }

    @Test func alignRightWithoutSuperlayerIsNoop() {
        let layer = CALayer()
        layer.frame = CGRect(x: 10, y: 10, width: 40, height: 20)
        layer.alignRight(margin: 5)
        #expect(layer.frame.origin.x == 10)
    }

    // MARK: - alignBottom

    @Test func alignBottomDefaultMargin() {
        let parent = CALayer()
        parent.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        let child = CALayer()
        child.frame = CGRect(x: 10, y: 0, width: 40, height: 20)
        parent.addSublayer(child)

        child.alignBottom()

        #expect(child.frame.origin.y == 80)
        #expect(child.frame.origin.x == 10)
    }

    @Test func alignBottomWithMargin() {
        let parent = CALayer()
        parent.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        let child = CALayer()
        child.frame = CGRect(x: 10, y: 0, width: 40, height: 20)
        parent.addSublayer(child)

        child.alignBottom(margin: 8)

        #expect(child.frame.origin.y == 72)
    }

    // MARK: - placeRight

    @Test func placeRightOfSibling() {
        let parent = CALayer()
        parent.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
        let sibling = CALayer()
        sibling.frame = CGRect(x: 20, y: 10, width: 50, height: 20)
        let child = CALayer()
        child.frame = CGRect(x: 0, y: 15, width: 30, height: 20)
        parent.addSublayer(sibling)
        parent.addSublayer(child)

        child.placeRight(of: sibling, spacing: 8)

        #expect(child.frame.origin.x == 78)
        #expect(child.frame.origin.y == 15)
    }

    @Test func placeRightZeroSpacing() {
        let sibling = CALayer()
        sibling.frame = CGRect(x: 10, y: 0, width: 40, height: 20)
        let child = CALayer()
        child.frame = CGRect(x: 0, y: 0, width: 30, height: 20)

        child.placeRight(of: sibling)

        #expect(child.frame.origin.x == 50)
    }

    // MARK: - placeBelow

    @Test func placeBelowSibling() {
        let parent = CALayer()
        parent.frame = CGRect(x: 0, y: 0, width: 200, height: 300)
        let sibling = CALayer()
        sibling.frame = CGRect(x: 10, y: 20, width: 50, height: 30)
        let child = CALayer()
        child.frame = CGRect(x: 5, y: 0, width: 40, height: 20)
        parent.addSublayer(sibling)
        parent.addSublayer(child)

        child.placeBelow(sibling, spacing: 10)

        #expect(child.frame.origin.y == 60)
        #expect(child.frame.origin.x == 5)
    }

    // MARK: - fillWidth

    @Test func fillWidthDefaultInsets() {
        let parent = CALayer()
        parent.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        let child = CALayer()
        child.frame = CGRect(x: 0, y: 0, width: 50, height: 20)
        parent.addSublayer(child)

        child.fillWidth()

        #expect(child.frame.size.width == 200)
    }

    @Test func fillWidthWithInsets() {
        let parent = CALayer()
        parent.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        let child = CALayer()
        child.frame = CGRect(x: 10, y: 0, width: 50, height: 20)
        parent.addSublayer(child)

        child.fillWidth(left: 10, right: 15)

        #expect(child.frame.size.width == 175)
    }

    @Test func fillWidthWithoutSuperlayerIsNoop() {
        let layer = CALayer()
        layer.frame = CGRect(x: 0, y: 0, width: 50, height: 20)
        layer.fillWidth(left: 10, right: 10)
        #expect(layer.frame.size.width == 50)
    }

    // MARK: - fillWidth(before:)

    @Test func fillWidthBeforeSibling() {
        let parent = CALayer()
        parent.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
        let child = CALayer()
        child.frame = CGRect(x: 10, y: 0, width: 50, height: 20)
        let sibling = CALayer()
        sibling.frame = CGRect(x: 200, y: 0, width: 80, height: 20)
        parent.addSublayer(child)
        parent.addSublayer(sibling)

        child.fillWidth(before: sibling, spacing: 5)

        #expect(child.frame.size.width == 185)
    }

    // MARK: - fillHeight

    @Test func fillHeightDefaultInsets() {
        let parent = CALayer()
        parent.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        let child = CALayer()
        child.frame = CGRect(x: 0, y: 0, width: 50, height: 20)
        parent.addSublayer(child)

        child.fillHeight()

        #expect(child.frame.size.height == 100)
    }

    @Test func fillHeightWithInsets() {
        let parent = CALayer()
        parent.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        let child = CALayer()
        child.frame = CGRect(x: 0, y: 0, width: 50, height: 20)
        parent.addSublayer(child)

        child.fillHeight(top: 10, bottom: 5)

        #expect(child.frame.size.height == 85)
    }
}
