// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKTesting
import SPFKUtils
import Testing

@Suite(.tags(.nameTemplate, .renameOrganize))
struct NameTemplateArgumentsTests {
    @Test func everyDatePatternIsListedInOrder() {
        let template = NameTemplate(#"{date:YYYY?"Undated"}/{date:YYYY-MM-DD?"Undated"}"#)
        #expect(template.arguments(of: "date") == ["YYYY", "YYYY-MM-DD"])
    }

    @Test func aBareTokenHasNoArgument() {
        #expect(NameTemplate("{date}_{name}").arguments(of: "date") == [nil])
    }

    @Test func anOptionalSectionIsRead() {
        #expect(NameTemplate("{name}[ {date:YYYY}]").arguments(of: "date") == ["YYYY"])
    }

    @Test func aTemplateNotReadingTheValueHasNone() {
        #expect(NameTemplate("{name}").arguments(of: "date").isEmpty)
    }
}
