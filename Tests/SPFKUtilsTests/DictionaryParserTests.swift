// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKUtils
import Testing

private enum TestKey: String, DictionaryKey, CaseIterable {
    case name
    case age
    case active
    case score
    case url
    case items
    case nested
    case tags
    case precise
}

final class DictionaryParserTests {
    @Test func initFromJSON() throws {
        let json = """
        {"name": "test", "age": 42}
        """

        let parser = try DictionaryParser(jsonData: json)
        #expect(try parser.string(for: TestKey.name) == "test")
        #expect(try parser.int(for: TestKey.age) == 42)
    }

    @Test func initFromInvalidJSON() {
        #expect(throws: Error.self) {
            _ = try DictionaryParser(jsonData: "not json")
        }
    }

    @Test func initFromPayload() throws {
        let payload: KeyValueDictionary = ["name": "hello"]
        let parser = DictionaryParser(payload: payload)
        #expect(try parser.string(for: TestKey.name) == "hello")
    }

    @Test func stringForKey() throws {
        let parser = DictionaryParser(payload: ["name": "value"])
        #expect(try parser.string(for: TestKey.name) == "value")
    }

    @Test func stringForMissingKey() {
        let parser = DictionaryParser(payload: [:])
        #expect(throws: Error.self) {
            _ = try parser.string(for: TestKey.name)
        }
    }

    @Test func intForKey() throws {
        let parser = DictionaryParser(payload: ["age": 25])
        #expect(try parser.int(for: TestKey.age) == 25)
    }

    @Test func intForMissingKey() {
        let parser = DictionaryParser(payload: ["age": "notAnInt"])
        #expect(throws: Error.self) {
            _ = try parser.int(for: TestKey.age)
        }
    }

    @Test func boolForKey() throws {
        let parser = DictionaryParser(payload: ["active": true])
        #expect(try parser.bool(for: TestKey.active) == true)
    }

    @Test func boolFromStringValue() throws {
        let parser = DictionaryParser(payload: ["active": "true"])
        #expect(try parser.bool(for: TestKey.active) == true)
    }

    @Test func floatForKey() throws {
        let parser = DictionaryParser(payload: ["score": Float(3.14)])
        let value = try parser.float(for: TestKey.score)
        #expect(abs(value - 3.14) < 0.01)
    }

    @Test func doubleForKey() throws {
        let parser = DictionaryParser(payload: ["precise": Double(3.14159265)])
        let value = try parser.double(for: TestKey.precise)
        #expect(abs(value - 3.14159265) < 0.0001)
    }

    @Test func urlForFileKey() throws {
        let parser = DictionaryParser(payload: ["url": "/Users/test/file.txt"])
        let url = try parser.url(for: TestKey.url)
        #expect(url.isFileURL)
        #expect(url.path == "/Users/test/file.txt")
    }

    @Test func urlForWebKey() throws {
        let parser = DictionaryParser(payload: ["url": "https://example.com"])
        let url = try parser.url(for: TestKey.url)
        #expect(url.absoluteString == "https://example.com")
    }

    @Test func stringsForKey() throws {
        let parser = DictionaryParser(payload: ["tags": ["a", "b", "c"]])
        let values = try parser.strings(for: TestKey.tags)
        #expect(values == ["a", "b", "c"])
    }

    @Test func dictionaryForKey() throws {
        let inner: KeyValueDictionary = ["name": "inner"]
        let parser = DictionaryParser(payload: ["nested": inner])
        let dict = try parser.dictionary(for: TestKey.nested)
        #expect(dict["name"] as? String == "inner")
    }

    @Test func dictionariesForKey() throws {
        let inner: [KeyValueDictionary] = [["name": "a"], ["name": "b"]]
        let parser = DictionaryParser(payload: ["items": inner])
        let dicts = try parser.dictionaries(for: TestKey.items)
        #expect(dicts.count == 2)
    }

    @Test func jsonValue() throws {
        let parser = DictionaryParser(payload: ["name": "test"])
        let data = try #require(parser.jsonValue)
        let string = try #require(String(data: data, encoding: .utf8))
        #expect(string.contains("test"))
    }

    @Test func description() throws {
        let parser = DictionaryParser(payload: ["name": "test"])
        #expect(parser.description.contains("test"))
    }
}
