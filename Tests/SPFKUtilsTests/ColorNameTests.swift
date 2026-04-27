// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import SPFKBase
import Testing

@testable import SPFKUtils

@Suite
final class ColorNameTests {
    // MARK: - Pure hue bucketing

    @Test func pureRed() throws {
        let color = try #require(HexColor(string: "FF0000"))
        #expect(color.colorName == .red)
    }

    @Test func pureOrange() {
        let color = HexColor(hue: 30, saturation: 1, brightness: 1)
        #expect(color.colorName == .orange)
    }

    @Test func pureYellow() throws {
        let color = try #require(HexColor(string: "FFFF00"))
        #expect(color.colorName == .yellow)
    }

    @Test func pureGreen() throws {
        let color = try #require(HexColor(string: "00FF00"))
        #expect(color.colorName == .green)
    }

    @Test func pureCyan() {
        let color = HexColor(hue: 180, saturation: 1, brightness: 1)
        #expect(color.colorName == .cyan)
    }

    @Test func pureBlue() throws {
        let color = try #require(HexColor(string: "0000FF"))
        #expect(color.colorName == .blue)
    }

    @Test func purePurple() {
        let color = HexColor(hue: 270, saturation: 1, brightness: 1)
        #expect(color.colorName == .purple)
    }

    @Test func purePink() {
        let color = HexColor(hue: 320, saturation: 1, brightness: 1)
        #expect(color.colorName == .pink)
    }

    @Test func hueWrapsToRed() {
        let color = HexColor(hue: 350, saturation: 1, brightness: 1)
        #expect(color.colorName == .red)
    }

    // MARK: - Achromatic colors

    @Test func pureWhite() throws {
        let color = try #require(HexColor(string: "FFFFFF"))
        #expect(color.colorName == .white)
    }

    @Test func pureBlack() throws {
        let color = try #require(HexColor(string: "000000"))
        #expect(color.colorName == .black)
    }

    @Test func midGray() throws {
        let color = try #require(HexColor(string: "808080"))
        #expect(color.colorName == .gray)
    }

    @Test func darkGray() throws {
        let color = try #require(HexColor(string: "333333"))
        #expect(color.colorName == .gray)
    }

    @Test func lightGray() throws {
        let color = try #require(HexColor(string: "CCCCCC"))
        #expect(color.colorName == .gray)
    }

    // MARK: - Brown detection

    @Test func brown() {
        // Dark orange → brown
        let color = HexColor(hue: 30, saturation: 0.7, brightness: 0.4)
        #expect(color.colorName == .brown)
    }

    @Test func darkReddishBrown() {
        let color = HexColor(hue: 10, saturation: 0.6, brightness: 0.35)
        #expect(color.colorName == .brown)
    }

    // MARK: - Edge cases

    @Test func nearlyWhite() {
        let color = HexColor(hue: 60, saturation: 0.05, brightness: 0.95)
        #expect(color.colorName == .white)
    }

    @Test func pastelBlue() {
        let color = HexColor(hue: 210, saturation: 0.3, brightness: 0.9)
        #expect(color.colorName == .blue)
    }

    @Test func rawValueMatchesName() {
        #expect(ColorName.red.rawValue == "red")
        #expect(ColorName.blue.rawValue == "blue")
        #expect(ColorName.gray.rawValue == "gray")
    }
}
