// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

public struct NodeIdentifier: Sendable, Hashable, Equatable, Codable, CustomStringConvertible {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.parentId == rhs.parentId &&
            lhs.id == rhs.id
    }

    /// Leaf nodes have a parentId but a top level group node does not
    public var parentId: UUID? {
        willSet {
            previousParentId = parentId
        }
    }

    /// `UUID` to identify this instance
    public var id: UUID

    // MARK: - cached, transient values

    /// if the node was duplicated, the previous `id` is stored here for tracking changes
    public var originalId: UUID?

    /// when the node is moved, the prevoius `parentId` will be cached here
    public private(set) var previousParentId: UUID?

    public var description: String {
        "NodeIdentifier(id: \(id.uuidString), parentId: \(parentId?.uuidString ?? "nil"), " +
            "originalId: \(originalId?.uuidString ?? "nil"), previousParentId: \(previousParentId?.uuidString ?? "nil"))"
    }

    public init(parentId: UUID? = nil, id: UUID) {
        self.parentId = parentId
        self.id = id
    }

    enum CodingKeys: String, CodingKey {
        case parentId
        case id
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        parentId = try container.decodeIfPresent(UUID.self, forKey: .parentId)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(parentId, forKey: .parentId)
    }
}
