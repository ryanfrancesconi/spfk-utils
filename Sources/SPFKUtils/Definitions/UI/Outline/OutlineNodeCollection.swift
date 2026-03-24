// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)

    import AppKit
    import Foundation
    import SPFKBase

    /// Tree data structure for OutlineView UI.
    ///
    /// Supports arbitrary depth nesting of OutlineNode instances.
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
            Self.updateSortIndexes(of: &nodes)
        }

        private static func updateSortIndexes(of nodes: inout [OutlineNode]) {
            for i in 0 ..< nodes.count {
                nodes[i].sortIndex = i

                if nodes[i].hasChildren {
                    updateSortIndexes(of: &nodes[i].children)
                }
            }
        }

        public func lookup(uuids: [UUID]) -> [OutlineNode] {
            uuids.compactMap {
                lookup(uuid: $0)
            }
        }

        public func lookup(uuid: UUID) -> OutlineNode? {
            lookup(uuid: uuid, in: nodes)
        }

        private func lookup(uuid: UUID, in nodes: [OutlineNode]) -> OutlineNode? {
            for node in nodes {
                if node.id == uuid { return node }

                if let found = lookup(uuid: uuid, in: node.children) {
                    return found
                }
            }

            return nil
        }

        public mutating func update(node: OutlineNode, isExpanded: Bool) {
            for i in 0 ..< nodes.count where nodes[i] == node {
                nodes[i].isExpanded = isExpanded
                Log.debug(nodes[i].title, isExpanded)
            }
        }

        public mutating func update(nodes: [OutlineNode]) throws {
            for node in nodes {
                try update(node: node)
            }
        }

        public mutating func update(node: OutlineNode) throws {
            if Self.update(node: node, in: &nodes) { return }
            throw NSError(description: "Failed to find \(node) in data")
        }

        @discardableResult
        private static func update(node: OutlineNode, in nodes: inout [OutlineNode]) -> Bool {
            for i in 0 ..< nodes.count {
                if nodes[i].id == node.id {
                    nodes[i] = node
                    return true
                }

                if update(node: node, in: &nodes[i].children) {
                    return true
                }
            }

            return false
        }

        /// Finds a parent node at any depth to insert into
        @discardableResult
        public mutating func insert(node child: OutlineNode, in parentId: UUID, atIndex: Int? = nil) throws -> OutlineNode {
            let results = try insert(nodes: [child], in: parentId, atIndex: atIndex)

            guard let result = results.first else {
                throw NSError(description: "failed to insert")
            }

            return result
        }

        /// Updates parentId and sortIndex, finding the parent at any depth
        public mutating func insert(
            nodes children: [OutlineNode],
            in parentId: UUID,
            atIndex: Int? = nil
        ) throws -> [OutlineNode] {
            var children = children

            for i in 0 ..< children.count {
                children[i].nodeIdentifier.parentId = parentId
            }

            if Self.insertChildren(children, in: parentId, atIndex: atIndex, nodes: &nodes) {
                updateSortIndexes()
                let ids = children.map(\.id)
                return lookup(uuids: ids)
            }

            throw NSError(description: "Failed to find parentId (\(parentId)) in nodes")
        }

        private static func insertChildren(
            _ children: [OutlineNode],
            in parentId: UUID,
            atIndex: Int?,
            nodes: inout [OutlineNode]
        ) -> Bool {
            for i in 0 ..< nodes.count {
                if nodes[i].id == parentId {
                    if let atIndex, atIndex != -1, nodes[i].children.indices.contains(atIndex) {
                        nodes[i].children.insert(contentsOf: children, at: atIndex)
                    } else {
                        nodes[i].children.append(contentsOf: children)
                    }

                    nodes[i].isExpanded = true
                    return true
                }

                if insertChildren(children, in: parentId, atIndex: atIndex, nodes: &nodes[i].children) {
                    return true
                }
            }

            return false
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
            if Self.rename(id: id, title: title, in: &nodes) { return }
            throw NSError(description: "Failed to find \(id) in data")
        }

        private static func rename(id: UUID, title: String, in nodes: inout [OutlineNode]) -> Bool {
            for i in 0 ..< nodes.count {
                if nodes[i].id == id {
                    nodes[i].title = title
                    return true
                }

                if rename(id: id, title: title, in: &nodes[i].children) {
                    return true
                }
            }

            return false
        }

        /// - Parameter node: The `OutlineNode` to lookup
        /// - Returns: The relative index in the group of nodes. If the node
        /// is a child, it returns the child index in the parent node's children array
        public func indexOf(node: OutlineNode) -> Int? {
            // Top-level search
            for i in 0 ..< nodes.count where nodes[i] == node {
                return i
            }

            // Search in parent's children at any depth
            guard let parentId = node.nodeIdentifier.parentId,
                  let parentNode = lookup(uuid: parentId)
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
            if let removed = Self.remove(id: id, from: &nodes) { return removed }
            throw NSError(description: "Failed to find \(id) in data")
        }

        private static func remove(id: UUID, from nodes: inout [OutlineNode]) -> OutlineNode? {
            for i in 0 ..< nodes.count {
                if nodes[i].id == id {
                    return nodes.remove(at: i)
                }

                if let removed = remove(id: id, from: &nodes[i].children) {
                    return removed
                }
            }

            return nil
        }

        public mutating func removeAll() {
            nodes.removeAll()
        }

        public mutating func sortChildren(of node: OutlineNode) throws {
            guard node.children.isNotEmpty else {
                throw NSError(description: "No child nodes to sort")
            }

            let sorted = node.children.sorted { lhs, rhs in
                lhs.title.standardCompare(with: rhs.title)
            }

            if Self.setSortedChildren(sorted, for: node.id, in: &nodes) { return }
            throw NSError(description: "Didn't find \(node.titleAndID) in collection")
        }

        private static func setSortedChildren(
            _ children: [OutlineNode],
            for id: UUID,
            in nodes: inout [OutlineNode]
        ) -> Bool {
            for i in 0 ..< nodes.count {
                if nodes[i].id == id {
                    nodes[i].children = children
                    return true
                }

                if setSortedChildren(children, for: id, in: &nodes[i].children) {
                    return true
                }
            }

            return false
        }
    }

    extension OutlineNodeCollection: Codable, Serializable {}

    extension [OutlineNode] {
        public func duplicate() -> [OutlineNode] {
            map { $0.duplicate() }
        }
    }

#endif
