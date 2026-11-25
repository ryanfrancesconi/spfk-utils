// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKTesting
import SPFKUtils
import Testing

@Suite(.tags(.nameTemplate, .renameOrganize))
struct NameTemplateDatePartsCompletionTests {
    typealias DateParts = NameTemplate.DateParts

    private let created = DateParts(year: 2019, month: 2, day: 19, hour: 21, minute: 44, second: 10)

    @Test func aYearIsCompletedByALaterDateInThatYear() {
        #expect(DateParts(year: 2019).completed(by: created) == created)
    }

    @Test func aYearIsNotCompletedByALaterDateInAnotherYear() {
        #expect(DateParts(year: 2019).completed(by: DateParts(year: 2020, month: 1, day: 1)) == nil)
    }

    @Test func aMonthIsCompletedOnlyByALaterDateInThatMonth() {
        let february = DateParts(year: 2019, month: 2)

        #expect(february.completed(by: DateParts(year: 2019, month: 2, day: 19)) == DateParts(year: 2019, month: 2, day: 19))
        #expect(february.completed(by: DateParts(year: 2019, month: 3, day: 1)) == nil)
    }

    @Test func aFullDateCompletedByAnAgreeingDateIsItself() {
        #expect(created.completed(by: created) == created)
    }

    @Test func aDifferingTimeOnTheSameDayDisagrees() {
        let other = DateParts(year: 2019, month: 2, day: 19, hour: 9, minute: 0)
        #expect(created.completed(by: other) == nil)
    }

    @Test func aLaterDateWithoutAMonthAddsNothing() {
        #expect(DateParts(year: 2019).completed(by: DateParts(year: 2019)) == DateParts(year: 2019))
    }

    @Test func completionStopsAtTheFirstPartTheLaterDateLacks() {
        let dayOnly = DateParts(year: 2019, month: 2, day: 19)
        #expect(DateParts(year: 2019).completed(by: dayOnly) == dayOnly)
    }
}
