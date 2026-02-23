// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)

    import AppKit
    import Foundation

    /// Data structure for tree structures
    public struct OutlineNode: Equatable, Sendable, Hashable {
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.nodeIdentifier == rhs.nodeIdentifier
        }

        public var title: String
        public var isEditable: Bool = true
        public var symbolName: String?
        public var hexColor: HexColor?

        public var nodeIdentifier: NodeIdentifier

        public var children: [OutlineNode] = .init()
        public var isExpanded: Bool = false
        public var sortIndex: Int?

        public var isLeaf: Bool { nodeIdentifier.parentId != nil && children.isEmpty }

        public var id: UUID { nodeIdentifier.id }
        public var parentId: UUID? { nodeIdentifier.parentId }

        public var identifier: NSUserInterfaceItemIdentifier {
            let id = isLeaf ? "OutlineNodeLeaf" : "OutlineNodeGroup"
            return NSUserInterfaceItemIdentifier(id)
        }

        public subscript(childIndex index: Int) -> OutlineNode? {
            guard children.indices.contains(index) else { return nil }
            return children[index]
        }

        public var titleAndID: String {
            "\(title) (\(nodeIdentifier.id))"
        }

        public init(
            title: String,
            isEditable: Bool,
            symbolName: String?,
            hexColor: HexColor? = nil,
            nodeIdentifier: NodeIdentifier,
            children: [OutlineNode] = []
        ) {
            self.title = title
            self.isEditable = isEditable
            self.symbolName = symbolName
            self.hexColor = hexColor
            self.nodeIdentifier = nodeIdentifier
            self.children = children
        }

        public func duplicate() -> OutlineNode {
            var result = OutlineNode(
                title: "Copy of \(title)",
                isEditable: isEditable,
                symbolName: symbolName,
                hexColor: hexColor,
                nodeIdentifier: .init(parentId: nodeIdentifier.parentId, id: UUID()),
                children: children
            )

            result.nodeIdentifier.originalId = id

            return result
        }
    }

    extension OutlineNode: Codable {
        enum CodingKeys: String, CodingKey {
            case title
            case isEditable
            case symbolName
            case hexColor
            case children
            case isExpanded
            case nodeIdentifier
            case sortIndex
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            title = try container.decode(String.self, forKey: .title)
            isEditable = try container.decode(Bool.self, forKey: .isEditable)
            children = try container.decode([OutlineNode].self, forKey: .children)
            isExpanded = try container.decode(Bool.self, forKey: .isExpanded)
            nodeIdentifier = try container.decode(NodeIdentifier.self, forKey: .nodeIdentifier)

            symbolName = try? container.decodeIfPresent(String.self, forKey: .symbolName)
            sortIndex = try? container.decodeIfPresent(Int.self, forKey: .sortIndex)
            hexColor = try? container.decodeIfPresent(HexColor.self, forKey: .hexColor)
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encode(title, forKey: .title)
            try container.encode(isEditable, forKey: .isEditable)
            try container.encode(children, forKey: .children)
            try container.encode(isExpanded, forKey: .isExpanded)
            try container.encode(nodeIdentifier, forKey: .nodeIdentifier)

            try? container.encodeIfPresent(symbolName, forKey: .symbolName)
            try? container.encodeIfPresent(sortIndex, forKey: .sortIndex)
            try? container.encodeIfPresent(hexColor, forKey: .hexColor)
        }
    }

    extension OutlineNode: Serializable {}

#endif
