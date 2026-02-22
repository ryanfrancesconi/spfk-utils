import AppKit
import Foundation

/// Data structure for OutlineView UI.
///
/// A single level, non recursive group of nodes. Each top level OutlineNode may have
/// an array of children [OutlineNode]
public struct OutlineNodeCollection: Sendable, Hashable, Equatable {
    /// Only for top level parent nodes
    public subscript(index index: Int) -> OutlineNode? {
        guard nodes.indices.contains(index) else { return nil }
        return nodes[index]
    }

    /// Will recursively search for the node
    public subscript(uuid uuid: UUID) -> OutlineNode? {
        lookup(uuid: uuid)
    }

    // MARK: -

    public var count: Int { nodes.count }

    public var expandedElements: [OutlineNode] {
        nodes.filter(\.isExpanded)
    }

    public private(set) var nodes: [OutlineNode]

    public init(nodes: [OutlineNode] = []) {
        self.nodes = nodes
    }

    public func lookup(uuid: UUID) -> OutlineNode? {
        for node in nodes where node.id == uuid {
            return node
        }

        let allchildren = nodes.flatMap(\.children)

        for child in allchildren where child.id == uuid {
            return child
        }

        return nil
    }

    public mutating func update(node: OutlineNode, isExpanded: Bool) {
        for i in 0 ..< nodes.count where nodes[i] == node {
            nodes[i].isExpanded = isExpanded
        }
    }

    public mutating func update(node: OutlineNode) throws {
        for i in 0 ..< nodes.count {
            if nodes[i].id == node.id {
                nodes[i] = node
                return
            }

            for j in 0 ..< nodes[i].children.count where nodes[i].children[j].id == node.id {
                var node = node
                node.parentId = nodes[i].id
                nodes[i].children[j] = node
                return
            }
        }

        throw NSError(description: "Failed to find \(node) in data")
    }

    /// finds a top level group node to insert into
    public mutating func insert(child node: OutlineNode, in parentId: UUID) throws {
        for i in 0 ..< nodes.count where nodes[i].id == parentId {
            var node = node
            node.parentId = parentId
            nodes[i].children.append(node)
            nodes[i].isExpanded = true // expand parent
            return
        }

        throw NSError(description: "Failed to find parentId (\(parentId)) in nodes")
    }

    public mutating func append(node: OutlineNode) {
        nodes.append(node)
    }

    public mutating func rename(id: UUID, title: String) throws {
        for i in 0 ..< nodes.count {
            if nodes[i].id == id {
                nodes[i].title = title
                return
            }

            for j in 0 ..< nodes[i].children.count where nodes[i].children[j].id == id {
                nodes[i].children[j].title = title
                return
            }
        }

        throw NSError(description: "Failed to find \(id) in data")
    }

    /// - Parameter node: The `OutlineNode` to lookup
    /// - Returns: The relative index in the group of nodes. If the node
    /// is a child, it returns the child index in the parent node's children array
    public func indexOf(node: OutlineNode) -> Int? {
        if !node.isLeaf {
            for i in 0 ..< nodes.count where nodes[i] == node {
                return i
            }
        }

        guard let parentId = node.parentId,
              let parentNode = self[uuid: parentId]
        else { return nil }

        for i in 0 ..< parentNode.children.count where parentNode.children[i] == node {
            return i
        }

        return nil
    }

    @discardableResult
    public mutating func remove(nodes: [OutlineNode]) -> [OutlineNode] {
        let ids = nodes.compactMap(\.id)
        return remove(ids: ids)
    }

    @discardableResult
    public mutating func remove(ids: [UUID]) -> [OutlineNode] {
        var removed: [OutlineNode] = []

        for id in ids {
            do {
                try removed.append(
                    remove(id: id)
                )

            } catch {
                Log.error(error)
            }
        }

        return removed
    }

    @discardableResult
    public mutating func remove(id: UUID) throws -> OutlineNode {
        for i in 0 ..< nodes.count {
            if nodes[i].id == id {
                let value = nodes[i]

                nodes.remove(at: i)
                return value
            }

            for j in 0 ..< nodes[i].children.count where nodes[i].children[j].id == id {
                let value = nodes[i]

                nodes[i].children.remove(at: j)
                return value
            }
        }

        throw NSError(description: "Failed to find \(id) in data")
    }

    public mutating func removeAll() {
        nodes.removeAll()
    }
}
