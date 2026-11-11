// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import AudioToolbox
import CoreGraphics
import Foundation
import SPFKAudioBase
import SPFKBase
import SPFKUtils
import Testing

// MARK: - CGRect.largestCenteredSquare

final class CGRectTests {
    @Test func alreadySquare() {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 100)
        let square = rect.largestCenteredSquare()
        #expect(square == rect)
    }

    @Test func wideRect() {
        let rect = CGRect(x: 0, y: 0, width: 200, height: 100)
        let square = rect.largestCenteredSquare()
        #expect(square.width == 100)
        #expect(square.height == 100)
        #expect(square.origin.x == 50)
        #expect(square.origin.y == 0)
    }

    @Test func tallRect() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 200)
        let square = rect.largestCenteredSquare()
        #expect(square.width == 100)
        #expect(square.height == 100)
        #expect(square.origin.x == 0)
        #expect(square.origin.y == 50)
    }

    @Test func rectWithOffset() {
        let rect = CGRect(x: 10, y: 20, width: 300, height: 100)
        let square = rect.largestCenteredSquare()
        #expect(square.width == 100)
        #expect(square.height == 100)
        #expect(square.origin.x == 110)
        #expect(square.origin.y == 20)
    }
}

// MARK: - AUValue dB helpers

final class AUValueTests {
    @Test func dBValueUnity() {
        let value: AUValue = 1.0
        #expect(abs(value.dBValue - 0.0) < 0.001)
    }

    @Test func dBValueHalf() {
        let value: AUValue = 0.5
        // 20 * log10(0.5) ≈ -6.02
        #expect(abs(value.dBValue - -6.0206) < 0.01)
    }

    @Test func linearValueFromZeroDB() {
        let value: AUValue = 0.0
        #expect(abs(value.linearValue - 1.0) < 0.001)
    }

    @Test func linearValueRoundTrip() {
        let original: AUValue = 0.75
        let db = original.dBValue
        let back = db.linearValue
        #expect(abs(back - original) < 0.001)
    }

    @Test func dBStringInfinity() {
        let value: AUValue = -91.0
        #expect(value.dBString() == "∞")
    }

    @Test func dBStringZero() {
        let value: AUValue = 0.0
        #expect(value.dBString() == "0 dB")
    }

    @Test func dBStringPositive() {
        let value: AUValue = 3.0
        let str = value.dBString()
        #expect(str.hasPrefix("+"))
        #expect(str.hasSuffix("dB"))
    }

    @Test func dBStringNegative() {
        let value: AUValue = -6.0
        let str = value.dBString()
        #expect(str.hasPrefix("-"))
        #expect(str.hasSuffix("dB"))
    }
}

// MARK: - CGColor.toHex

final class CGColorHexTests {
    @Test func redNoAlpha() {
        let color = CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
        let hex = color.toHex(alpha: false)
        #expect(hex == "FF0000")
    }

    @Test func redWithAlpha() {
        let color = CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
        let hex = color.toHex(alpha: true)
        #expect(hex == "FF0000FF")
    }

    @Test func halfAlpha() {
        let color = CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 0.5)
        let hex = color.toHex(alpha: true)
        // 0.5 * 255 = 127.5, lroundf = 128 = 0x80
        #expect(hex == "FF000080")
    }

    @Test func black() {
        let color = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        let hex = color.toHex()
        #expect(hex == "000000")
    }

    @Test func white() {
        let color = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
        let hex = color.toHex()
        #expect(hex == "FFFFFF")
    }
}

// MARK: - ByteCount

final class ByteCountTests {
    @Test func toStringFormatting() throws {
        let result = try #require(ByteCount.toString(1_048_576))
        #expect(result == "1 MB")
    }
}
