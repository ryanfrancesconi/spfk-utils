// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import QuartzCore
import SPFKBase
import Testing

@testable import SPFKUtils

@Suite
@MainActor
final class CALayerLayoutTests {
    // MARK: - alignVertical

    @Test func alignVerticalCentersWithReferenceFrame() {
        let layer = CALayer()
        layer.frame = CGRect(x: 10, y: 0, width: 20, height: 10)

        let reference = CGRect(x: 50, y: 20, width: 100, height: 40)
        layer.alignVertical(with: reference)

        // Reference midY = 20 + 20 = 40, layer half-height = 5, expected y = 35
        #expect(layer.frame.origin.y == 35)
        // x should be unchanged
        #expect(layer.frame.origin.x == 10)
    }

    @Test func alignVerticalWithSameSizeFrame() {
        let layer = CALayer()
        layer.frame = CGRect(x: 0, y: 0, width: 30, height: 30)

        let reference = CGRect(x: 10, y: 10, width: 30, height: 30)
        layer.alignVertical(with: reference)

        #expect(layer.frame.origin.y == 10)
    }

    @Test func alignVerticalWithZeroHeightLayer() {
        let layer = CALayer()
        layer.frame = CGRect(x: 5, y: 0, width: 20, height: 0)

        let reference = CGRect(x: 0, y: 10, width: 50, height: 20)
        layer.alignVertical(with: reference)

        // Reference midY = 10 + 10 = 20, layer half-height = 0, expected y = 20
        #expect(layer.frame.origin.y == 20)
    }

    // MARK: - alignHorizontal

    @Test func alignHorizontalCentersWithReferenceFrame() {
        let layer = CALayer()
        layer.frame = CGRect(x: 0, y: 10, width: 20, height: 10)

        let reference = CGRect(x: 50, y: 0, width: 100, height: 40)
        layer.alignHorizontal(with: reference)

        // Reference midX = 50 + 50 = 100, layer half-width = 10, expected x = 90
        #expect(layer.frame.origin.x == 90)
        // y should be unchanged
        #expect(layer.frame.origin.y == 10)
    }

    @Test func alignHorizontalWithSameSizeFrame() {
        let layer = CALayer()
        layer.frame = CGRect(x: 0, y: 0, width: 40, height: 20)

        let reference = CGRect(x: 20, y: 5, width: 40, height: 20)
        layer.alignHorizontal(with: reference)

        #expect(layer.frame.origin.x == 20)
    }

    // MARK: - centerInSuperlayer

    @Test func centerInSuperlayer() {
        let parent = CALayer()
        parent.frame = CGRect(x: 0, y: 0, width: 200, height: 100)

        let child = CALayer()
        child.frame = CGRect(x: 0, y: 0, width: 40, height: 20)
        parent.addSublayer(child)

        child.centerInSuperlayer()

        #expect(child.frame.origin.x == 80)
        #expect(child.frame.origin.y == 40)
    }

    @Test func centerInSuperlayerWithoutParentIsNoop() {
        let layer = CALayer()
        layer.frame = CGRect(x: 15, y: 25, width: 10, height: 10)

        layer.centerInSuperlayer()

        // No superlayer, frame should be unchanged
        #expect(layer.frame.origin.x == 15)
        #expect(layer.frame.origin.y == 25)
    }

    // MARK: - centerVerticalInSuperlayer

    @Test func centerVerticalInSuperlayer() {
        let parent = CALayer()
        parent.frame = CGRect(x: 0, y: 0, width: 200, height: 100)

        let child = CALayer()
        child.frame = CGRect(x: 30, y: 0, width: 40, height: 20)
        parent.addSublayer(child)

        child.centerVerticalInSuperlayer()

        // x preserved, y centered
        #expect(child.frame.origin.x == 30)
        #expect(child.frame.origin.y == 40)
    }

    // MARK: - centerHorizontalInSuperlayer

    @Test func centerHorizontalInSuperlayerOddWidth() {
        let parent = CALayer()
        parent.frame = CGRect(x: 0, y: 0, width: 200, height: 100)

        let child = CALayer()
        child.frame = CGRect(x: 0, y: 15, width: 41, height: 20)
        parent.addSublayer(child)

        child.centerHorizontalInSuperlayer()

        // (200/2) - (41/2) = 79.5
        #expect(child.frame.origin.x == 79.5)
        // y preserved
        #expect(child.frame.origin.y == 15)
    }

    @Test func centerHorizontalEvenWidthNoSnapping() {
        let parent = CALayer()
        parent.frame = CGRect(x: 0, y: 0, width: 200, height: 100)

        let child = CALayer()
        child.frame = CGRect(x: 0, y: 10, width: 40, height: 20)
        parent.addSublayer(child)

        child.centerHorizontalInSuperlayer()

        // (200/2) - (40/2) = 80, already integer
        #expect(child.frame.origin.x == 80)
    }
}
