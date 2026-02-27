import AppKit
import Foundation
import SPFKBase

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
        updateSortIndexes()
    }

    public mutating func updateSortIndexes() {
        for i in 0 ..< nodes.count {
            nodes[i].sortIndex = i
            // Log.debug(i, nodes[i].titleAndID)

            for j in 0 ..< nodes[i].children.count {
                nodes[i].children[j].sortIndex = j
                // Log.debug("    *", j, nodes[i].children[j].titleAndID)
            }
        }
    }

    public func lookup(uuids: [UUID]) -> [OutlineNode] {
        uuids.compactMap {
            lookup(uuid: $0)
        }
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
            Log.debug(nodes[i].title, isExpanded)
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
                node.nodeIdentifier.parentId = nodes[i].id
                nodes[i].children[j] = node
                return
            }
        }

        throw NSError(description: "Failed to find \(node) in data")
    }

    /// finds a top level group node to insert into
    @discardableResult
    public mutating func insert(node child: OutlineNode, in parentId: UUID, atIndex: Int? = nil) throws -> OutlineNode {
        let results = try insert(nodes: [child], in: parentId, atIndex: atIndex)

        guard let result = results.first else {
            throw NSError(description: "failed to insert")
        }

        return result
    }

    /// updates parentId and sortIndex
    public mutating func insert(
        nodes children: [OutlineNode],
        in parentId: UUID,
        atIndex: Int? = nil
    ) throws -> [OutlineNode] {
        //
        var children = children

        for i in 0 ..< children.count {
            // Update the parentId for its new group
            children[i].nodeIdentifier.parentId = parentId
        }

        for i in 0 ..< nodes.count where nodes[i].id == parentId {
            //
            if let atIndex, atIndex != -1, nodes[i].children.indices.contains(atIndex) {
                nodes[i].children.insert(contentsOf: children, at: atIndex)

            } else {
                nodes[i].children.append(contentsOf: children)
            }

            nodes[i].isExpanded = true // expand parent

            updateSortIndexes()

            let ids = children.map(\.id)
            return lookup(uuids: ids)
        }

        throw NSError(description: "Failed to find parentId (\(parentId)) in nodes")
    }

    public mutating func append(groupNodes incoming: [OutlineNode]) {
        let nodeState = nodes

        _ = try? remove(nodes: incoming)
        nodes.append(contentsOf: incoming)
        updateSortIndexes()

        for node in nodeState {
            for i in 0 ..< nodes.count where nodes[i].id == node.id {
                nodes[i].isExpanded = node.isExpanded
            }
        }
    }

    public mutating func insert(groupNodes incoming: [OutlineNode], atIndex: Int?) {
        let nodeState = nodes

        var atIndex = atIndex ?? nodes.count

        if let occupyingNode = self[index: atIndex], !occupyingNode.isEditable {
            atIndex += 1
        }

        guard nodes.indices.contains(atIndex) else {
            append(groupNodes: incoming)
            return
        }

        _ = try? remove(nodes: incoming)

        nodes.insert(contentsOf: incoming, at: atIndex)
        updateSortIndexes()

        for node in nodeState {
            for i in 0 ..< nodes.count where nodes[i].id == node.id {
                nodes[i].isExpanded = node.isExpanded
            }
        }
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

        guard let parentId = node.nodeIdentifier.parentId,
              let parentNode = self[uuid: parentId]
        else { return nil }

        for i in 0 ..< parentNode.children.count where parentNode.children[i] == node {
            return i
        }

        return nil
    }

    @discardableResult
    public mutating func remove(nodes: [OutlineNode]) throws -> [OutlineNode] {
        let ids = nodes.compactMap(\.id)
        return try remove(ids: ids)
    }

    @discardableResult
    public mutating func remove(ids: [UUID]) throws -> [OutlineNode] {
        defer {
            updateSortIndexes()
        }

        var removed: [OutlineNode] = []

        for id in ids {
            try removed.append(
                remove(id: id)
            )
        }

        return removed
    }

    @discardableResult
    mutating func remove(id: UUID) throws -> OutlineNode {
        for i in 0 ..< nodes.count {
            if nodes[i].id == id {
                let value = nodes[i]
                nodes.remove(at: i)
                return value
            }

            for j in 0 ..< nodes[i].children.count where nodes[i].children[j].id == id {
                let value = nodes[i].children[j]
                nodes[i].children.remove(at: j)
                return value
            }
        }

        throw NSError(description: "Failed to find \(id) in data")
    }

    public mutating func removeAll() {
        nodes.removeAll()
    }

    public mutating func sortChildren(of node: OutlineNode) throws {
        guard node.children.isNotEmpty else {
            throw NSError(description: "No child nodes to sort")
        }

        let children = node.children.sorted { lhs, rhs in
            lhs.title.standardCompare(with: rhs.title)
        }

        for i in 0 ..< nodes.count where nodes[i] == node {
            nodes[i].children = children
            return
        }

        throw NSError(description: "Didn't find \(node.titleAndID) in collection")
    }
}

extension OutlineNodeCollection: Codable, Serializable {}

extension [OutlineNode] {
    public func duplicate() -> [OutlineNode] {
        map { $0.duplicate() }
    }
}
