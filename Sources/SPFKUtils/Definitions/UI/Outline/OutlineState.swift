// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// Persisted expanded/collapsed state for a single outline group node, identified by UUID.
public struct OutlineState: Sendable, Hashable, Equatable, Codable {
    public var id: UUID
    public var isExpanded: Bool

    public init(id: UUID, isExpanded: Bool) {
        self.id = id
        self.isExpanded = isExpanded
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        isExpanded = try container.decodeIfPresent(Bool.self, forKey: .isExpanded) ?? true
    }
}
