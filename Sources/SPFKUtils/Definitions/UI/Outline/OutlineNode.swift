// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)

    import AppKit
    import Foundation
    import SPFKBase

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
        public var hasChildren: Bool { children.isNotEmpty }
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

    extension OutlineNode: Codable, Serializable {
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
            isEditable = try container.decodeIfPresent(Bool.self, forKey: .isEditable) ?? true
            symbolName = try container.decodeIfPresent(String.self, forKey: .symbolName)
            hexColor = try container.decodeIfPresent(HexColor.self, forKey: .hexColor)
            nodeIdentifier = try container.decodeIfPresent(NodeIdentifier.self, forKey: .nodeIdentifier) ?? NodeIdentifier(id: UUID())
            children = try container.decodeIfPresent([OutlineNode].self, forKey: .children) ?? []
            isExpanded = try container.decodeIfPresent(Bool.self, forKey: .isExpanded) ?? false
            sortIndex = try container.decodeIfPresent(Int.self, forKey: .sortIndex)
        }
    }

#endif
