// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKTesting
import Testing

@testable import SPFKUtils

@Suite(.tags(.nameTemplate, .renameOrganize))
struct NameTemplateArgumentValueTests {
    private let context = NameTemplate.RenderContext(index: 1, count: 1, collection: "")

    private func render(_ source: String, _ values: [String: NameTemplate.Value]) -> String {
        NameTemplate(source).render(values: values, context: context)
    }

    @Test func aKeyedValueAnswersItsArgumentAndTheBareValueTheBareToken() {
        let values: [String: NameTemplate.Value] = ["fxName": .text("Door Creak"), "fxName:title": .text("Old Door")]

        #expect(render("{fxName:title}", values) == "Old Door")
        #expect(render("{fxName}", values) == "Door Creak")
    }

    @Test func anArgumentWithNoKeyedValueFallsBackToTheBareValue() {
        #expect(render("{fxName:ixml}", ["fxName": .text("Door Creak")]) == "Door Creak")
    }

    @Test func dateArgumentsStillFormatAndFieldsStillReadTheirKey() {
        let date = NameTemplate.DateParts(year: 2026, month: 3, day: 9)
        let values: [String: NameTemplate.Value] = ["date": .date(date), "field:Camera": .text("X100"), "field": .text("bare")]

        #expect(render("{date:YYYY}", values) == "2026")
        #expect(render("{field:Camera}", values) == "X100")
        #expect(render("{field:Lens}", values) == "")
    }

    @Test func aFallbackChainPassesOverAnEmptyKeyedValue() {
        let values: [String: NameTemplate.Value] = ["fxName:title": .text("  "), "name": .text("take 3")]

        #expect(render("{fxName:title?name}", values) == "take 3")
    }
}
