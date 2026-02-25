// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// Convenience protocol for property list data
public protocol Serializable: SerializableEncoder, SerializableDecoder, Sendable {}

public protocol SerializableEncoder: Encodable {}
public protocol SerializableDecoder: Decodable {}

extension SerializableEncoder {
    public var dataRepresentation: Data? {
        do {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .binary

            return try encoder.encode(self)
        } catch {
            Log.error(error)
        }

        return nil
    }

    public var base64EncodedString: String? {
        dataRepresentation?.base64EncodedString()
    }

    public var plistRepresentation: String? {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml

        guard let data = try? encoder.encode(self) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
}

extension SerializableDecoder {
    public init(base64Encoded string: String) throws {
        guard let data = Data(base64Encoded: string) else {
            throw NSError(description: "Failed to parse \(string)")
        }

        try self.init(data: data)
    }

    public init(plist string: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw NSError(description: "Failed to parse plist \(string)")
        }

        try self.init(data: data)
    }

    public init(data: Data) throws {
        self = try PropertyListDecoder().decode(Self.self, from: data)
    }
}
