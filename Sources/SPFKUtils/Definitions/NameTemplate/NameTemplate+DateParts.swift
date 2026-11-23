// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

extension NameTemplate {
    /// A wall-clock date, possibly partial: a year-only tag has no month.
    public struct DateParts: Sendable, Hashable {
        public var year: Int
        public var month: Int?
        public var day: Int?
        public var hour: Int?
        public var minute: Int?
        public var second: Int?

        /// What `{date}` means with no pattern.
        public static let defaultPattern = "YYYY-MM-DD"

        public init(year: Int, month: Int? = nil, day: Int? = nil, hour: Int? = nil, minute: Int? = nil, second: Int? = nil) {
            self.year = year
            self.month = month
            self.day = day
            self.hour = hour
            self.minute = minute
            self.second = second
        }

        /// `date` on the Gregorian calendar in `timeZone`.
        public init(_ date: Date, timeZone: TimeZone) {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)

            self.init(
                year: components.year ?? 0,
                month: components.month,
                day: components.day,
                hour: components.hour,
                minute: components.minute,
                second: components.second
            )
        }
    }
}

// MARK: - Parsing

extension NameTemplate.DateParts {
    /// Reads `YYYY`, `YYYY-MM`, `YYYY-MM-DD` and a following `hh:mm[:ss]`, with any single
    /// non-digit separator. Whatever follows the last part read, a zone or a fraction, is ignored.
    /// Nil unless the string starts with a four-digit year.
    public init?(parsing string: String) {
        let characters = Array(string)
        var position = 0

        /// The next `count` digits after one separator (none for the first part), or nil.
        func next(_ count: Int, separated: Bool) -> Int?? {
            var i = position

            if separated {
                guard i < characters.count, !characters[i].isASCIIDigit else { return .some(nil) }
                i += 1
            }

            guard i + count <= characters.count else { return .some(nil) }
            let digits = characters[i ..< i + count]
            guard digits.allSatisfy(\.isASCIIDigit), let value = Int(String(digits)) else { return .some(nil) }

            // A part running straight into another digit is not a part of this form.
            if i + count < characters.count, characters[i + count].isASCIIDigit { return nil }

            position = i + count
            return .some(value)
        }

        guard case let .some(year?) = next(4, separated: false) else { return nil }
        self.init(year: year)

        let ranges: [(WritableKeyPath<Self, Int?>, ClosedRange<Int>)] = [
            (\.month, 1 ... 12), (\.day, 1 ... 31), (\.hour, 0 ... 23), (\.minute, 0 ... 59), (\.second, 0 ... 60),
        ]

        for (keyPath, range) in ranges {
            guard case let .some(read) = next(2, separated: true) else { return nil }
            guard let value = read else { break }
            guard range.contains(value) else { return nil }
            self[keyPath: keyPath] = value
        }

        // An hour without its minute is not a time.
        if hour != nil && minute == nil { hour = nil }
    }
}

// MARK: - Plausibility

extension NameTemplate.DateParts {
    /// Whether this can be when a file was captured: not before 1990, and not more than a day after
    /// `now`. Missing parts count as their earliest value.
    public func isPlausibleCaptureDate(now: Date = Date(), timeZone: TimeZone = .current) -> Bool {
        guard year >= 1990 else { return false }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = DateComponents(
            year: year, month: month ?? 1, day: day ?? 1, hour: hour ?? 0, minute: minute ?? 0, second: second ?? 0
        )

        guard let date = calendar.date(from: components) else { return false }
        return date <= now.addingTimeInterval(24 * 60 * 60)
    }

    /// ``isPlausibleCaptureDate(now:timeZone:)`` for a stored instant, without a calendar.
    public static func isPlausibleCaptureDate(_ date: Date, now: Date = Date(), timeZone: TimeZone = .current) -> Bool {
        let earliestUTC = Date(timeIntervalSince1970: 631_152_000) // 1990-01-01 00:00 UTC
        let earliest = earliestUTC.addingTimeInterval(-Double(timeZone.secondsFromGMT(for: earliestUTC)))

        return date >= earliest && date <= now.addingTimeInterval(24 * 60 * 60)
    }
}

// MARK: - Formatting

extension NameTemplate.DateParts {
    private static let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    /// Longest first, so `YYYY` is not read as two `YY`.
    private static let patternParts = ["YYYY", "MMM", "YY", "MM", "DD", "hh", "mm", "ss"]

    /// `pattern` with each part substituted and anything else literal. Nil when the pattern needs a
    /// part this date lacks. `MMM` is English whatever the locale.
    public func formatted(_ pattern: String) -> String? {
        var result = ""
        var rest = Substring(pattern)

        while let first = rest.first {
            guard let part = Self.patternParts.first(where: { rest.hasPrefix($0) }) else {
                result.append(first)
                rest = rest.dropFirst()
                continue
            }

            guard let text = text(for: part) else { return nil }
            result += text
            rest = rest.dropFirst(part.count)
        }

        return result
    }

    private func text(for part: String) -> String? {
        func padded(_ value: Int?, _ width: Int) -> String? {
            guard let value else { return nil }
            let digits = String(value.magnitude)
            return String(repeating: "0", count: max(0, width - digits.count)) + digits
        }

        switch part {
        case "YYYY": return padded(year, 4)
        case "YY": return padded(year % 100, 2)
        case "MMM": return month.flatMap { (1 ... 12).contains($0) ? Self.monthNames[$0 - 1] : nil }
        case "MM": return padded(month, 2)
        case "DD": return padded(day, 2)
        case "hh": return padded(hour, 2)
        case "mm": return padded(minute, 2)
        case "ss": return padded(second, 2)
        default: return nil
        }
    }
}

extension Character {
    fileprivate var isASCIIDigit: Bool {
        isASCII && isNumber
    }
}
