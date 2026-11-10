// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
@testable import SPFKUtils
import Testing

struct XMLScannerTests {
    /// Each token as text: `<name attr>`, `</name>`, or its decoded content.
    private func tokens(_ xml: String) throws -> [String] {
        var scanner = XMLScanner(Data(xml.utf8))
        var output = [String]()

        while let token = try scanner.next() {
            switch token {
            case let .start(name, attributes):
                let attributeText = String(decoding: scanner.bytes[attributes], as: UTF8.self)
                output.append("<\(String(decoding: scanner.bytes[name], as: UTF8.self))\(attributeText)>")
            case let .end(name):
                output.append("</\(String(decoding: scanner.bytes[name], as: UTF8.self))>")
            case let .text(range):
                output.append(scanner.text(range))
            case let .cdata(range):
                output.append("CDATA:" + String(decoding: scanner.bytes[range], as: UTF8.self))
            }
        }

        return output
    }

    @Test func prologCommentsAndDoctypeAreSkipped() throws {
        let xml = #"<?xml version="1.0"?><!DOCTYPE x><!-- a <b> comment --><a>1</a>"#

        #expect(try tokens(xml) == ["<a>", "1", "</a>"])
    }

    @Test func aSelfClosingElementGivesAStartAndAnEnd() throws {
        #expect(try tokens(#"<row><c r="B2" s="3"/><br/></row>"#) == [
            "<row>", #"<c r="B2" s="3">"#, "</c>", "<br>", "</br>", "</row>",
        ])
    }

    @Test func aGreaterThanInsideAQuotedAttributeDoesNotEndTheTag() throws {
        var scanner = XMLScanner(Data(#"<a x='1>2' y="it's"/>"#.utf8))

        guard case let .start(_, attributes) = try scanner.next() else {
            Issue.record("expected a start tag")
            return
        }

        #expect(scanner.attribute(Array("x".utf8), in: attributes) == "1>2")
        #expect(scanner.attribute(Array("y".utf8), in: attributes) == "it's")
        #expect(scanner.attribute(Array("z".utf8), in: attributes) == nil)
    }

    @Test func entityAndCharacterReferencesResolve() throws {
        #expect(try tokens("<t>&amp;&lt;&gt;&quot;&apos; &#233;&#x1F3BA; &bogus; & alone</t>") == [
            "<t>", "&<>\"' é🎺 &bogus; & alone", "</t>",
        ])
    }

    @Test func lineEndsNormalizeToLineFeedAsAParserReportsThem() throws {
        #expect(try tokens("<t>a\r\nb\rc\nd</t>")[1] == "a\nb\nc\nd")
    }

    @Test func cdataIsReportedRaw() throws {
        #expect(try tokens("<t><![CDATA[a <b> &amp;]]></t>") == ["<t>", "CDATA:a <b> &amp;", "</t>"])
    }

    @Test func namesCompareByLocalNameIgnoringThePrefix() throws {
        var scanner = XMLScanner(Data(#"<x:row r:id="rId1" sheetId="2">"#.utf8))

        guard case let .start(name, attributes) = try scanner.next() else {
            Issue.record("expected a start tag")
            return
        }

        #expect(scanner.isName(name, Array("row".utf8)))
        #expect(!scanner.isName(name, Array("ow".utf8)))
        #expect(scanner.attribute(Array("id".utf8), in: attributes) == "rId1")
        #expect(scanner.attribute(Array("Id".utf8), in: attributes) == nil)
    }

    @Test(arguments: ["<a", "<a><!-- open", "<a><![CDATA[open", "<?xml"])
    func unterminatedMarkupThrows(xml: String) {
        #expect(throws: XMLScanner.Malformed.self) {
            try tokens(xml)
        }
    }
}
