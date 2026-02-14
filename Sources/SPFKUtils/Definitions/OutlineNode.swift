// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)

    import AppKit
    import Foundation

    /// Data structure for OutlineView
    public struct OutlineNode: Equatable, Sendable, Hashable {
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }

        public var title: String
        public var children: [OutlineNode] = .init()
        public var isExpanded: Bool = false
        public var parentId: UUID?
        public let id: UUID?
        public var sortIndex: Int?
        public var symbolName: String?

        public var isLeaf: Bool { parentId != nil && children.isEmpty }

        public var identifier: NSUserInterfaceItemIdentifier {
            let id = isLeaf ? "OutlineNodeLeaf" : "OutlineNodeGroup"
            return NSUserInterfaceItemIdentifier(id)
        }

        public subscript(childIndex index: Int) -> OutlineNode? {
            guard children.indices.contains(index) else { return nil }
            return children[index]
        }

        public var titleAndID: String {
            "\(title) (\(id?.uuidString ?? "nil")"
        }

        public init(title: String, symbolName: String?, parentId: UUID?, id: UUID?, children: [OutlineNode] = []) {
            self.title = title
            self.symbolName = symbolName
            self.id = id
            self.parentId = parentId
            self.children = children
        }
    }

    extension OutlineNode: Codable {
        enum CodingKeys: String, CodingKey {
            case title
            case symbolName
            case children
            case isExpanded
            case parentId
            case id
            case sortIndex
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            title = try container.decode(String.self, forKey: .title)
            children = try container.decode([OutlineNode].self, forKey: .children)
            isExpanded = try container.decode(Bool.self, forKey: .isExpanded)

            symbolName = try? container.decodeIfPresent(String.self, forKey: .symbolName)

            parentId = try? container.decodeIfPresent(UUID.self, forKey: .parentId)
            id = try? container.decodeIfPresent(UUID.self, forKey: .id)

            sortIndex = try? container.decodeIfPresent(Int.self, forKey: .sortIndex)
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encode(title, forKey: .title)
            try container.encode(children, forKey: .children)
            try container.encode(isExpanded, forKey: .isExpanded)

            try? container.encodeIfPresent(symbolName, forKey: .symbolName)

            try? container.encodeIfPresent(parentId, forKey: .parentId)
            try? container.encodeIfPresent(id, forKey: .id)

            try? container.encodeIfPresent(sortIndex, forKey: .sortIndex)
        }
    }

#endif
