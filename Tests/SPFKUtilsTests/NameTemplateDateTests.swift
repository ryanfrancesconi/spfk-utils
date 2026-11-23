// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKTesting
import Testing

@testable import SPFKUtils

@Suite(.tags(.nameTemplate))
struct NameTemplateDateTests {
    typealias DateParts = NameTemplate.DateParts

    private let full = DateParts(year: 2019, month: 5, day: 7, hour: 13, minute: 4, second: 9)

    private func render(_ source: String, _ parts: DateParts?, key: String = "date") -> String {
        let values: [String: NameTemplate.Value] = parts.map { [key: .date($0)] } ?? [:]
        return NameTemplate(source).render(values: values, context: .init(index: 1, count: 1))
    }

    // MARK: - Patterns

    @Test(arguments: [
        ("{date:YYYY}", "2019"),
        ("{date:YY}", "19"),
        ("{date:MM}", "05"),
        ("{date:MMM}", "May"),
        ("{date:DD}", "07"),
        ("{date:hh}", "13"),
        ("{date:mm}", "04"),
        ("{date:ss}", "09"),
        ("{date:YYYYMMDD}", "20190507"),
        ("{date:YYYY-MM-DD hh.mm.ss}", "2019-05-07 13.04.09"),
        ("{date:DD MMM YYYY}", "07 May 2019"),
        ("{date:Q YYYY}", "Q 2019"),
        ("{date}", "2019-05-07"),
    ])
    func eachPatternPartFormats(source: String, expected: String) {
        #expect(render(source, full) == expected)
    }

    @Test func theFileDatesFormatLikeTheCaptureDate() {
        #expect(render("{created:YYYY-MM}", full, key: "created") == "2019-05")
        #expect(render("{modified}", full, key: "modified") == "2019-05-07")
    }

    /// The month name is fixed English text, never a formatter's, so no locale reaches it.
    @Test func theMonthNameIsEnglish() {
        let months = (1 ... 12).map { render("{date:MMM}", DateParts(year: 2019, month: $0)) }
        #expect(months == ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"])
    }

    @Test func aPartialDateRendersOnlyThePartsItHas() {
        let year = DateParts(year: 2019)

        #expect(render("{date:YYYY}", year) == "2019")
        #expect(render("{date:YYYY-MM}", year) == "")
        #expect(render("{date:YYYY-MM?\"Undated\"}", year) == "Undated")
        #expect(render("{date:YYYY-MM-DD hh}", DateParts(year: 2019, month: 5, day: 7)) == "")
    }

    @Test func anUndatedFileLeavesTheTokenEmpty() {
        #expect(render("{date:YYYY-MM-DD}_x", nil) == "_x")
    }

    // MARK: - From a Date

    @Test func aDateIsReadInTheZoneGiven() throws {
        // 2019-05-07 20:00 UTC: still the 7th in Los Angeles, already the 8th in Auckland.
        let date = Date(timeIntervalSince1970: 1_557_259_200)
        let losAngeles = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let auckland = try #require(TimeZone(identifier: "Pacific/Auckland"))

        #expect(DateParts(date, timeZone: losAngeles) == DateParts(year: 2019, month: 5, day: 7, hour: 13, minute: 0, second: 0))
        #expect(DateParts(date, timeZone: auckland) == DateParts(year: 2019, month: 5, day: 8, hour: 8, minute: 0, second: 0))
    }

    // MARK: - Parsing

    @Test(arguments: [
        ("2019", DateParts(year: 2019)),
        ("2019-05", DateParts(year: 2019, month: 5)),
        ("2019-05-07", DateParts(year: 2019, month: 5, day: 7)),
        ("2019:05:07", DateParts(year: 2019, month: 5, day: 7)),
        ("2019-05-07T13:04:05Z", DateParts(year: 2019, month: 5, day: 7, hour: 13, minute: 4, second: 5)),
        ("2019-05-07T13:04:05.250+02:00", DateParts(year: 2019, month: 5, day: 7, hour: 13, minute: 4, second: 5)),
        ("2019-05-07 13:04", DateParts(year: 2019, month: 5, day: 7, hour: 13, minute: 4)),
        ("2019:05:07 13:04:05", DateParts(year: 2019, month: 5, day: 7, hour: 13, minute: 4, second: 5)),
    ])
    func aDateStringParses(string: String, expected: DateParts) {
        #expect(DateParts(parsing: string) == expected)
    }

    @Test(arguments: ["", "abc", "19-05-07", "2019-13-01", "201905"])
    func aNonDateIsRefused(string: String) {
        #expect(DateParts(parsing: string) == nil)
    }

    // MARK: - Plausibility

    @Test func theBoundsRefuseEarlyAndFutureDates() throws {
        let utc = try #require(TimeZone(identifier: "UTC"))
        let now = Date(timeIntervalSince1970: 1_763_900_000)

        #expect(!DateParts(year: 0, month: 1, day: 1).isPlausibleCaptureDate(now: now, timeZone: utc))
        #expect(!DateParts(year: 1989, month: 12, day: 31).isPlausibleCaptureDate(now: now, timeZone: utc))
        #expect(DateParts(year: 1990, month: 1, day: 1).isPlausibleCaptureDate(now: now, timeZone: utc))
        #expect(DateParts(now.addingTimeInterval(23 * 3600), timeZone: utc).isPlausibleCaptureDate(now: now, timeZone: utc))
        #expect(!DateParts(now.addingTimeInterval(25 * 3600), timeZone: utc).isPlausibleCaptureDate(now: now, timeZone: utc))
    }

    /// The instant check agrees with the parts check either side of 1990 in the zone given.
    @Test func aStoredInstantIsBoundedInTheZoneGiven() throws {
        let tokyo = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let now = Date(timeIntervalSince1970: 1_763_900_000)
        let earliestUTC = Date(timeIntervalSince1970: 631_152_000)

        for date in [earliestUTC.addingTimeInterval(-9 * 3600 - 1), earliestUTC.addingTimeInterval(-9 * 3600), earliestUTC] {
            #expect(
                DateParts.isPlausibleCaptureDate(date, now: now, timeZone: tokyo)
                    == DateParts(date, timeZone: tokyo).isPlausibleCaptureDate(now: now, timeZone: tokyo)
            )
        }

        #expect(!DateParts.isPlausibleCaptureDate(Date(timeIntervalSince1970: 0), now: now, timeZone: tokyo))
        #expect(!DateParts.isPlausibleCaptureDate(now.addingTimeInterval(25 * 3600), now: now, timeZone: tokyo))
    }
}
