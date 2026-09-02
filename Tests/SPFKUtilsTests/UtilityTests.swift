// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import AudioToolbox
import CoreGraphics
import Foundation
import SPFKAudioBase
import SPFKBase
import SPFKUtils
import Testing

// MARK: - URL.isParent

final class URLParentTests {
    @Test func directoryIsParent() {
        let parent = URL(fileURLWithPath: NSTemporaryDirectory())
        let child = parent.appendingPathComponent("somefile.txt")
        #expect(parent.isParent(of: child))
    }

    @Test func unrelatedPathsNotParent() {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
        let other = URL(fileURLWithPath: "/System/Library")
        #expect(!dir.isParent(of: other))
    }

    @Test func deepChildIsStillChild() {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
        let child = dir.appendingPathComponent("sub/deep/file.txt")
        #expect(dir.isParent(of: child))
    }
}

// MARK: - URL.queryStringParameter

final class QueryStringTests {
    @Test func basicParam() {
        let url = URL(string: "https://example.com?name=test")!
        #expect(url.queryStringParameter("name") == "test")
    }

    @Test func multipleParams() {
        let url = URL(string: "https://example.com?a=1&b=2&c=3")!
        #expect(url.queryStringParameter("b") == "2")
    }

    @Test func missingParam() {
        let url = URL(string: "https://example.com?name=test")!
        #expect(url.queryStringParameter("missing") == nil)
    }

    @Test func encodedValue() {
        let url = URL(string: "https://example.com?name=hello%20world")!
        #expect(url.queryStringParameter("name") == "hello world")
    }
}

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

// MARK: - CGSize.init(equal:)

final class CGSizeTests {
    @Test func equalInit() {
        let size = CGSize(equal: 42)
        #expect(size.width == 42)
        #expect(size.height == 42)
    }

    @Test func zeroInit() {
        let size = CGSize(equal: 0)
        #expect(size.width == 0)
        #expect(size.height == 0)
    }
}

// MARK: - ClosedRange<TimeInterval>.duration

final class ClosedRangeTests {
    @Test func duration() {
        let range: ClosedRange<TimeInterval> = 1.0 ... 5.0
        #expect(range.duration == 4.0)
    }

    @Test func zeroDuration() {
        let range: ClosedRange<TimeInterval> = 3.0 ... 3.0
        #expect(range.duration == 0)
    }

    @Test func negativeLowerBound() {
        let range: ClosedRange<TimeInterval> = -2.0 ... 3.0
        #expect(range.duration == 5.0)
    }
}

// MARK: - Bool.string

final class BoolExtensionTests {
    @Test func trueString() {
        #expect(true.string == "true")
    }

    @Test func falseString() {
        #expect(false.string == "false")
    }
}

// MARK: - UUID.zero

final class UUIDExtensionTests {
    @Test func zeroUUID() {
        let zero = UUID.zero
        #expect(zero.uuidString == "00000000-0000-0000-0000-000000000000")
    }

    @Test func zeroAddingByte() {
        let uuid = UUID.zero(adding: 1)
        #expect(uuid.uuidString == "00000000-0000-0000-0000-000000000001")
    }

    @Test func zeroAddingMaxByte() {
        let uuid = UUID.zero(adding: 255)
        #expect(uuid.uuidString == "00000000-0000-0000-0000-0000000000FF")
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

// MARK: - TimeInterval / mach time

final class TimeIntervalTests {
    @Test func hostTimeRoundTrip() {
        let original: TimeInterval = 1.0
        let hostTime = original.convertedToHostTime()
        let back = hostTime.hostTimeConvertedToTimeInterval()
        #expect(abs(back - original) < 0.001)
    }

    @Test func zeroConversion() {
        let zero: TimeInterval = 0
        let hostTime = zero.convertedToHostTime()
        #expect(hostTime == 0)
    }

    @Test func machTimeConstants() {
        #expect(machTimeSecondsPerTick > 0)
        #expect(machTimeTicksPerSecond > 0)
        // They should be reciprocals (approximately)
        #expect(abs(machTimeSecondsPerTick * machTimeTicksPerSecond - 1.0) < 0.0001)
    }
}

// MARK: - NumberFormatter

final class NumberFormatterTests {
    @Test func decimalStringFromInt() {
        let result = NumberFormatter.decimalString(from: 1000)
        #expect(result != nil)
        #expect(result?.contains(",") == true || result?.contains(".") == true || result == "1000")
    }

    @Test func decimalStringFromDouble() {
        let result = NumberFormatter.decimalString(from: 1234.5)
        #expect(result != nil)
    }
}

// MARK: - CGColor.toHex

final class CGColorHexTests {
    @Test func redNoAlpha() {
        let color = CGColor(red: 1, green: 0, blue: 0, alpha: 1)
        let hex = color.toHex(alpha: false)
        #expect(hex == "FF0000")
    }

    @Test func redWithAlpha() {
        let color = CGColor(red: 1, green: 0, blue: 0, alpha: 1)
        let hex = color.toHex(alpha: true)
        #expect(hex == "FF0000FF")
    }

    @Test func halfAlpha() {
        let color = CGColor(red: 1, green: 0, blue: 0, alpha: 0.5)
        let hex = color.toHex(alpha: true)
        // 0.5 * 255 = 127.5, lroundf = 128 = 0x80
        #expect(hex == "FF000080")
    }

    @Test func black() {
        let color = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        let hex = color.toHex()
        #expect(hex == "000000")
    }

    @Test func white() {
        let color = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        let hex = color.toHex()
        #expect(hex == "FFFFFF")
    }
}

// MARK: - Dictionary.merge

final class DictionaryMergeTests {
    @Test func mergeOverrides() {
        var dict: [String: Int] = ["a": 1, "b": 2]
        dict.merge(dictionaries: ["b": 3, "c": 4])
        #expect(dict["a"] == 1)
        #expect(dict["b"] == 3)
        #expect(dict["c"] == 4)
    }

    @Test func mergeMultiple() {
        var dict: [String: Int] = ["a": 1]
        dict.merge(dictionaries: ["b": 2], ["c": 3])
        #expect(dict.count == 3)
    }

    @Test func mergeEmpty() {
        var dict: [String: Int] = ["a": 1]
        dict.merge(dictionaries: [:])
        #expect(dict == ["a": 1])
    }
}

// MARK: - ByteCount

final class ByteCountTests {
    @Test func byte() {
        #expect(ByteCount.byte.rawValue == 1)
    }

    @Test func kilobyte() {
        #expect(ByteCount.kilobyte.rawValue == 1024)
    }

    @Test func megabyte() {
        #expect(ByteCount.megabyte.rawValue == 1_048_576)
    }

    @Test func gigabyte() {
        #expect(ByteCount.gigabyte.rawValue == 1_073_741_824)
    }

    @Test func terabyte() {
        #expect(ByteCount.terabyte.rawValue == 1_099_511_627_776)
    }

    @Test func sizesAreMultiples() {
        #expect(ByteCount.megabyte.rawValue == ByteCount.kilobyte.rawValue * 1024)
        #expect(ByteCount.gigabyte.rawValue == ByteCount.megabyte.rawValue * 1024)
        #expect(ByteCount.terabyte.rawValue == ByteCount.gigabyte.rawValue * 1024)
    }

    @Test func fromString() throws {
        let size1 = try #require(ByteCount.fromString("1 KB"))
        #expect(size1 == ByteCount.kilobyte.rawValue)

        let size2 = try #require(ByteCount.fromString("1 MB"))
        #expect(size2 == ByteCount.megabyte.rawValue)

        let size3 = try #require(ByteCount.fromString("1 GB"))
        #expect(size3 == ByteCount.gigabyte.rawValue)

        let size4 = try #require(ByteCount.fromString("1 TB"))
        #expect(size4 == ByteCount.terabyte.rawValue)

        let size5 = try #require(ByteCount.fromString("160.2 MB"))
        #expect(size5 == 167_981_875)

        let size6 = try #require(ByteCount.fromString("765.5 MB")).double
        #expect(size6 == 765.5 * ByteCount.megabyte.rawValue.double)
    }

    @Test func toStringFormatting() throws {
        let result = try #require(ByteCount.toString(1_048_576))
        #expect(result == "1 MB")
    }
}

#if os(macOS)

    // MARK: - NSEdgeInsets

    import Foundation

    final class NSEdgeInsetsTests {
        @Test func equalInit() {
            let insets = NSEdgeInsets(equal: 10)
            #expect(insets.top == 10)
            #expect(insets.left == 10)
            #expect(insets.bottom == 10)
            #expect(insets.right == 10)
        }

        @Test func zeroInit() {
            let insets = NSEdgeInsets(equal: 0)
            #expect(insets.top == 0)
            #expect(insets.left == 0)
        }
    }
#endif
