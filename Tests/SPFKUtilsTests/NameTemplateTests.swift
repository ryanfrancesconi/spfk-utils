// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKTesting
import Testing

@testable import SPFKUtils

@Suite(.tags(.nameTemplate))
struct NameTemplateTests {
    typealias Value = NameTemplate.Value

    static let lexemeInputs = [
        "IMG {date:YYYY-MM-DD} {seq:3}",
        " lead, trail; ",
        "{{literal}}",
        "[_{creator}]",
        "{title?\"Untitled\"|upper}",
        "{date:YYYY}/{date:YYYY-MM-DD}",
        "a{b",
        "a}b",
        "[x",
        "Take [1]",
        "",
    ]

    private func render(
        _ source: String,
        _ values: [String: Value] = [:],
        index: Int = 1,
        count: Int = 1,
        collection: String = ""
    ) -> String {
        NameTemplate(source).render(values: values, context: .init(index: index, count: count, collection: collection))
    }

    // MARK: - Lexemes

    @Test(arguments: lexemeInputs)
    func theLexemesReassembleTheSourceExactly(source: String) {
        #expect(NameTemplate(source).lexemes.map(\.source).joined() == source)
    }

    @Test func tokensAreSeparatedFromText() {
        #expect(NameTemplate("IMG {date:YYYY-MM-DD} {seq:3}").lexemes == [
            .text("IMG "), .token("{date:YYYY-MM-DD}"), .text(" "), .token("{seq:3}"),
        ])
        #expect(NameTemplate("{{literal}}").lexemes == [.text("{{literal}}")])
        #expect(NameTemplate("a{b").lexemes == [.text("a{b")])
        #expect(NameTemplate("[_{creator}]").lexemes == [.text("[_"), .token("{creator}"), .text("]")])
    }

    @Test func aTemplateStoresAsItsSource() throws {
        let template = NameTemplate("{date:YYYY}_{seq:2}")
        let data = try JSONEncoder().encode(template)

        #expect(String(decoding: data, as: UTF8.self) == "\"{date:YYYY}_{seq:2}\"")
        #expect(try JSONDecoder().decode(NameTemplate.self, from: data) == template)
    }

    // MARK: - Render

    @Test func literalsAndEscapedBraces() {
        #expect(render("Trip") == "Trip")
        #expect(render("{{literal}}") == "{literal}")
        #expect(render("a}b") == "a}b")
    }

    @Test func eachSharedTokenReadsItsValue() {
        let values: [String: Value] = [
            "name": .text("IMG_0001"), "ext": .text("heic"), "folder": .text("Trip"), "title": .text("Beach"),
            "text": .text("Custom"),
        ]

        #expect(render("{name}.{ext}", values) == "IMG_0001.heic")
        #expect(render("{folder} {title} {text}", values) == "Trip Beach Custom")
        #expect(render("{collection} {seq}", values, index: 2, count: 3, collection: "Road Trip") == "Road Trip 2")
    }

    @Test func aFieldTokenIsKeyedByItsIdentifier() {
        #expect(render("{field:iptc.city}", ["field:iptc.city": .text("Paris")]) == "Paris")
        #expect(render("{field:Camera}", ["field:iptc.city": .text("Paris")]) == "")
    }

    @Test func anUnknownTokenRendersEmpty() {
        #expect(render("a{nothing}b") == "ab")
    }

    @Test func aValueIsTrimmedButLiteralTextIsNot() {
        #expect(render("x{title}y", ["title": .text("  Beach  ")]) == "xBeachy")
        #expect(render("x  {title}  y", ["title": .text(" a ")]) == "x  a  y")
    }

    // MARK: - Fallback

    @Test func theFirstNonEmptyAlternativeIsTaken() {
        #expect(render("{title?name}", ["title": .text("Beach"), "name": .text("IMG")]) == "Beach")
        #expect(render("{title?name}", ["name": .text("IMG")]) == "IMG")
        #expect(render("{title?folder?name}", ["title": .text(""), "name": .text("IMG")]) == "IMG")
    }

    @Test func aQuotedLiteralEndsTheChain() {
        #expect(render("{title?\"Untitled\"}") == "Untitled")
        #expect(render("{date:YYYY?\"Undated\"}") == "Undated")
    }

    @Test func aWhitespaceValueCountsAsEmpty() {
        #expect(render("{title?name}", ["title": .text("   "), "name": .text("IMG")]) == "IMG")
    }

    // MARK: - Modifiers

    @Test(arguments: [
        ("{title|upper}", "BEACH DAY"),
        ("{title|lower}", "beach day"),
        ("{title|title}", "Beach Day"),
        ("{title|first:3}", "BEA"),
        ("{title|replace: =_}", "BEACH_day"),
        ("{title|replace:day=}", "BEACH"),
        ("{title|lower|replace: =-}", "beach-day"),
    ])
    func eachModifierChangesTheValue(source: String, expected: String) {
        #expect(render(source, ["title": .text("BEACH day")]) == expected)
    }

    @Test func trimRemovesWhitespaceAModifierLeft() {
        #expect(render("[{title|replace:x= |trim}]", ["title": .text("xax")]) == "a")
    }

    @Test func modifiersApplyToTheChosenAlternative() {
        #expect(render("{title?name|upper}", ["name": .text("img")]) == "IMG")
        #expect(render("{title?\"untitled\"|upper}") == "UNTITLED")
    }

    @Test func modifiersApplyToAFormattedDate() {
        let date = Value.date(.init(year: 2019, month: 5, day: 7))
        #expect(render("{date:DD MMM|upper}", ["date": date]) == "07 MAY")
    }

    // MARK: - Optional sections

    @Test func aSectionIsDroppedWhenATokenInsideIsEmpty() {
        #expect(render("IMG[_{creator}]", [:]) == "IMG")
        #expect(render("IMG[_{creator}_{title}]", ["creator": .text("Ann")]) == "IMG")
        #expect(render("IMG[_{creator}]", ["creator": .text("   ")]) == "IMG")
    }

    @Test func aSectionIsKeptWhenEveryTokenIsFilled() {
        #expect(render("IMG[_{creator}_{title}]", ["creator": .text("Ann"), "title": .text("Sea")]) == "IMG_Ann_Sea")
    }

    @Test func aSectionWithNoTokenIsLiteral() {
        #expect(render("Take [1]") == "Take [1]")
        #expect(render("[x") == "[x")
    }

    // MARK: - Folder levels

    @Test func aSlashInTheTemplateSplitsLevels() {
        let date = Value.date(.init(year: 2019, month: 5, day: 7))
        let template = NameTemplate("{date:YYYY}/{date:YYYY-MM-DD}")

        #expect(template.renderLevels(values: ["date": date], context: .init(index: 1, count: 1)) == ["2019", "2019-05-07"])
    }

    @Test func anEmptyLevelIsDropped() {
        let template = NameTemplate("{title}/{name}")
        #expect(template.renderLevels(values: ["name": .text("a")], context: .init(index: 1, count: 1)) == ["a"])
    }

    @Test func eachLevelIsSanitizedOnItsOwn() {
        let template = NameTemplate("{title}/{name}")
        let levels = template.renderLevels(values: ["title": .text(" ..AC:DC "), "name": .text("x ")], context: .init(index: 1, count: 1))

        #expect(levels == ["AC-DC", "x"])
    }

    @Test func aSlashInAValueDoesNotSplit() {
        let template = NameTemplate("{title}")
        #expect(template.renderLevels(values: ["title": .text("AC/DC")], context: .init(index: 1, count: 1)) == ["AC-DC"])
    }

    @Test func aNameRendersASlashAsADash() {
        #expect(render("{title}/x", ["title": .text("a")]) == "a-x")
    }

    // MARK: - Sequence

    @Test func theDefaultWidthIsTheCountsDigits() {
        #expect(render("{seq}", index: 1, count: 9) == "1")
        #expect(render("{seq}", index: 1, count: 10) == "01")
        #expect(render("{seq}", index: 10, count: 10) == "10")
    }

    @Test func aWidthAndAStartAreHonored() {
        #expect(render("{seq:3}", index: 2, count: 5) == "002")
        #expect(render("{seq:2,start=0}", index: 1, count: 5) == "00")
        #expect(render("{seq:2,start=0}", index: 3, count: 5) == "02")
        #expect(render("{seq:1}", index: 12, count: 20) == "12")
    }

    // MARK: - Sanitizing

    @Test func sanitizingNeverChangesCase() {
        #expect(render("{title}", ["title": .text("iPhone 15 Pro")]) == "iPhone 15 Pro")
    }

    @Test func sanitizingDropsLeadingDotsAndReplacesSeparators() {
        #expect(NameTemplate.sanitizedName("  ..AC/DC: Live  ") == "AC-DC- Live")
        #expect(NameTemplate.sanitizedLevel(".hidden: a") == "hidden- a")
    }

    @Test func aLongNameIsCutOnAWholeCharacter() {
        let long = String(repeating: "é", count: 150)
        let name = NameTemplate.sanitizedName(long)
        let level = NameTemplate.sanitizedLevel(long + "é")

        #expect(name.utf8.count <= NameTemplate.maximumNameByteCount && name.utf8.count > 230)
        #expect(name.allSatisfy { $0 == "é" })
        #expect(level.utf8.count <= NameTemplate.maximumLevelByteCount && level.utf8.count > 245)
        #expect(level.allSatisfy { $0 == "é" })
    }

    // MARK: - Malformed

    @Test(arguments: lexemeInputs + ["{", "}", "{}", "{{", "}}", "[]", "[{", "{seq:99999999999}", "{seq:-3,start=x}", "{|}", "{?}", "{title?\"unclosed}", "{title|first:-1}", "{title|replace:}"])
    func malformedInputRendersWithoutCrashing(source: String) {
        _ = render(source, ["title": .text("t")], index: 3, count: 4)
    }

    @Test func malformedBracesAreLiteral() {
        #expect(render("a{b") == "a{b")
        #expect(render("[_{x") == "[_{x")
        #expect(render("{}") == "{}")
    }

    @Test func theURLValuesNameTheFile() {
        let values = NameTemplate.urlValues(for: URL(fileURLWithPath: "/Volumes/Photos/Trip/IMG_0001.HEIC"))
        #expect(values == ["name": .text("IMG_0001"), "ext": .text("HEIC"), "folder": .text("Trip")])
    }
}
