// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import AEXML
import Foundation
import SPFKUtils
import Testing

final class PlistUtilitiesTests {
    @Test func dictionaryToPlistRoundTrip() throws {
        let original: KeyValueDictionary = [
            "name": "test",
            "value": 42,
            "flag": true,
        ]

        let plistDoc = try PlistUtilities.dictionaryToPlist(dictionary: original)
        let restored = try PlistUtilities.plistToDictionary(element: plistDoc.root)

        #expect(restored["name"] as? String == "test")
        #expect(restored["value"] as? Int == 42)
        #expect(restored["flag"] as? Bool == true)
    }

    @Test func plistToDictionaryWithNestedDict() throws {
        let inner: KeyValueDictionary = ["key": "val"]
        let original: KeyValueDictionary = [
            "nested": inner,
        ]

        let plistDoc = try PlistUtilities.dictionaryToPlist(dictionary: original)
        let restored = try PlistUtilities.plistToDictionary(element: plistDoc.root)

        let restoredInner = restored["nested"] as? KeyValueDictionary
        #expect(restoredInner?["key"] as? String == "val")
    }

    @Test func emptyDictionary() throws {
        let original: KeyValueDictionary = [:]
        let plistDoc = try PlistUtilities.dictionaryToPlist(dictionary: original)
        let restored = try PlistUtilities.plistToDictionary(element: plistDoc.root)
        #expect(restored.isEmpty)
    }

    @Test func stringValues() throws {
        let original: KeyValueDictionary = [
            "a": "hello",
            "b": "world",
        ]

        let plistDoc = try PlistUtilities.dictionaryToPlist(dictionary: original)
        let restored = try PlistUtilities.plistToDictionary(element: plistDoc.root)
        #expect(restored["a"] as? String == "hello")
        #expect(restored["b"] as? String == "world")
    }
}
