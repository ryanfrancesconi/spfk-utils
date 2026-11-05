// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKUtils
import Testing

struct XMLValidationTests {
    @Test func wellFormedXMLIsValid() throws {
        guard case let .valid(prettyPrinted) = XMLValidation.validate(string: "<root><child>text</child></root>") else {
            Issue.record("Expected .valid")
            return
        }

        #expect(prettyPrinted.contains("<root>"))
        #expect(prettyPrinted.contains("<child>text</child>"))
    }

    @Test func validXMLIsPrettyPrinted() {
        guard case let .valid(prettyPrinted) = XMLValidation.validate(string: "<root><a><b>text</b></a></root>") else {
            Issue.record("Expected .valid")
            return
        }

        #expect(prettyPrinted.contains("\n"))
    }

    @Test func unterminatedXMLIsInvalidWithADescription() {
        guard case let .invalid(errorDescription) = XMLValidation.validate(string: "<root><unclosed>") else {
            Issue.record("Expected .invalid")
            return
        }

        #expect(errorDescription.hasPrefix("XML parse error:"))
        #expect(errorDescription.contains("line"))
    }

    @Test func emptyStringIsInvalid() {
        guard case .invalid = XMLValidation.validate(string: "") else {
            Issue.record("Expected .invalid for an empty string")
            return
        }
    }

    @Test func anXMPPacketIsValid() {
        let xmp = """
        <?xpacket begin="\u{feff}" id="W5M0MpCehiHzreSzNTczkc9d"?>
        <x:xmpmeta xmlns:x="adobe:ns:meta/">
            <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
                <rdf:Description rdf:about=""/>
            </rdf:RDF>
        </x:xmpmeta>
        <?xpacket end="w"?>
        """

        guard case .valid = XMLValidation.validate(string: xmp) else {
            Issue.record("Expected .valid for an XMP packet")
            return
        }
    }

    @Test func anIXMLChunkIsValid() {
        let ixml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <BWFXML>
            <SPEED>
                <NOTE>Test note</NOTE>
            </SPEED>
        </BWFXML>
        """

        guard case .valid = XMLValidation.validate(string: ixml) else {
            Issue.record("Expected .valid for iXML")
            return
        }
    }
}
