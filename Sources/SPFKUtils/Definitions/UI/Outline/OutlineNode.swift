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

        /// Identity, matching `==`. Without this, Swift synthesizes a hash over every stored
        /// property, so a node whose title, children or sort index have moved on hashes apart from
        /// the one it equals -- and `NSOutlineView.row(forItem:)` is a hash lookup.
        public func hash(into hasher: inout Hasher) {
            hasher.combine(nodeIdentifier)
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

        /// A copy of the whole subtree, every node carrying a fresh identity and an `originalId`
        /// naming what it came from.
        ///
        /// Children are re-parented onto the copy. Anything resolving a copied node against a
        /// store keys off `originalId`, so a child without one is silently skipped there.
        ///
        /// - Parameter siblingTitles: the titles already present where the copy is going. The
        ///   "Copy of" prefix is applied only when this holds the title, so a paste into another
        ///   group keeps the name the user gave it. No default: only the caller knows the
        ///   destination, and one that has not thought about it renames every paste. Children are
        ///   unaffected -- a child's siblings all travel with it, so nothing new collides.
        public func duplicate(siblingTitles: Set<String>) -> OutlineNode {
            let title = siblingTitles.contains(title) ? "Copy of \(title)" : title

            return duplicate(title: title, parentId: nodeIdentifier.parentId)
        }

        private func duplicate(title: String, parentId: UUID?) -> OutlineNode {
            let newId = UUID()

            var result = OutlineNode(
                title: title,
                isEditable: isEditable,
                symbolName: symbolName,
                hexColor: hexColor,
                nodeIdentifier: .init(parentId: parentId, id: newId),
                children: children.map { $0.duplicate(title: $0.title, parentId: newId) }
            )

            result.nodeIdentifier.originalId = id

            // A group that arrives collapsed hides everything the copy just produced.
            result.isExpanded = isExpanded

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
