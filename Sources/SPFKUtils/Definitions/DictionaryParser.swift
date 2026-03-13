// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKBase

public protocol DictionaryKey: RawRepresentable<String>, CaseIterable, Hashable {}

/// Convenience handlers for parsing JSON data
public struct DictionaryParser {
    public private(set) var payload: KeyValueDictionary

    public var jsonValue: Data? {
        try? JSONSerialization.data(
            withJSONObject: payload,
            options: []
        )
    }

    public var plistValue: Data? {
        try? PropertyListSerialization.data(
            fromPropertyList: payload,
            format: .xml,
            options: .init()
        )
    }

    public init(jsonData: String) throws {
        guard let data = jsonData.data(using: .utf8) else {
            throw NSError(description: "Failed to convert to data")
        }

        guard let payload = try JSONSerialization.jsonObject(
            with: data,
            options: []
        ) as? KeyValueDictionary else {
            throw NSError(description: "Failed to parse JSON")
        }

        self = DictionaryParser(payload: payload)
    }

    public init(payload: KeyValueDictionary) {
        self.payload = payload
    }

    public func dictionary(for key: any DictionaryKey) throws -> KeyValueDictionary {
        guard let value = payload[key.rawValue] as? KeyValueDictionary else {
            throw NSError(description: "No '\(key)' in payload")
        }
        return value
    }

    public func dictionaries(for key: any DictionaryKey) throws -> [KeyValueDictionary] {
        guard let value = payload[key.rawValue] as? [KeyValueDictionary] else {
            throw NSError(description: "No '\(key)' in payload. The full payload is: \(jsonValue?.toString(using: .utf8) ?? "nil")")
        }
        return value
    }

    public func strings(for key: any DictionaryKey) throws -> [String] {
        guard let value = payload[key.rawValue] as? [String] else {
            throw NSError(description: "No '\(key)' in payload")
        }
        return value
    }

    public func string(for key: any DictionaryKey) throws -> String {
        guard let value = payload[key.rawValue] as? String else {
            throw NSError(description: "No '\(key)' in payload")
        }

        return value
    }

    public func url(for key: any DictionaryKey) throws -> URL {
        guard let value = payload[key.rawValue] as? String else {
            throw NSError(description: "No '\(key)' in payload")
        }

        let fileURL = value.first == "/"

        if fileURL {
            return URL(fileURLWithPath: value)
        }

        guard let url = URL(string: value) else {
            throw NSError(description: "Failed to parse URL with path \(value)")
        }

        return url
    }

    public func bool(for key: any DictionaryKey) throws -> Bool {
        if let value = payload[key.rawValue] as? Bool {
            return value
        }

        let string = try string(for: key)

        return string.boolValue
    }

    public func int(for key: any DictionaryKey) throws -> Int {
        guard let value = payload[key.rawValue] as? Int else {
            throw NSError(description: "No '\(key)' in payload")
        }

        return value
    }

    public func float(for key: any DictionaryKey) throws -> Float {
        guard let value = payload[key.rawValue] as? Float else {
            throw NSError(description: "No '\(key)' in payload")
        }

        return value
    }

    public func double(for key: any DictionaryKey) throws -> Double {
        guard let value = payload[key.rawValue] as? Double else {
            throw NSError(description: "No '\(key)' in payload")
        }

        return value
    }
}

extension DictionaryParser: CustomStringConvertible {
    public var description: String {
        jsonValue?.toString(using: .utf8) ?? "nil"
    }

    public func print() {
        Log.debug(self)
    }
}
