// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import AppKit
    import Foundation
    import SPFKBase
    import SPFKTesting
    import Testing

    @testable import SPFKUtils

    final class OutlineNodeCollectionTests: TestCaseModel {
        var uuids: [UUID] = []

        // Dummy Data
        func nextUUID() throws -> UUID {
            guard uuids.count < UInt8.max else {
                throw NSError(description: "Limited to \(UInt8.max) values")
            }

            let byte = UInt8(uuids.count)
            let next = UUID.zero(adding: byte)
            uuids.append(next)

            return next
        }

        func create(nodeCount: Int, childrenCount: Int) throws -> OutlineNodeCollection {
            var nodes: [OutlineNode] = []

            for i in 0 ..< nodeCount {
                let gid = try nextUUID()

                var children = [OutlineNode]()

                for c in 0 ..< childrenCount {
                    let cid = try nextUUID()

                    children.append(
                        OutlineNode(title: "Playlist \(i).\(c)", isEditable: true, symbolName: "playlist", nodeIdentifier: .init(parentId: gid, id: cid))
                    )
                }

                nodes.append(
                    OutlineNode(title: "Group \(i)", isEditable: true, symbolName: "folder", nodeIdentifier: .init(parentId: nil, id: gid), children: children)
                )
            }

            return OutlineNodeCollection(nodes: nodes)
        }

        @Test func lookup() throws {
            let collection = try create(nodeCount: 2, childrenCount: 2)

            #expect(collection[uuid: uuids[0]]?.title == "Group 0")
            #expect(collection[uuid: uuids[1]]?.title == "Playlist 0.0")
            #expect(collection[uuid: uuids[2]]?.title == "Playlist 0.1")
            #expect(collection[uuid: uuids[3]]?.title == "Group 1")
            #expect(collection[uuid: uuids[4]]?.title == "Playlist 1.0")
            #expect(collection[uuid: uuids[5]]?.title == "Playlist 1.1")

            let _5 = collection.lookup(uuid: uuids[5])
            #expect(_5?.title == "Playlist 1.1")
        }

        @Test func rename() throws {
            var collection = try create(nodeCount: 2, childrenCount: 2)

            try collection.rename(id: uuids[1], title: "New Title")
            #expect(collection[uuid: uuids[1]]?.title == "New Title")
        }

        @Test func update() throws {
            var collection = try create(nodeCount: 2, childrenCount: 2)

            // update() does a raw replacement, so the incoming node must carry the correct parentId
            let node = OutlineNode(title: "New Playlist", isEditable: true, symbolName: "playlist", nodeIdentifier: .init(parentId: uuids[3], id: uuids[5]))

            try collection.update(node: node)
            let newNode = try #require(collection[uuid: uuids[5]])
            #expect(newNode.title == "New Playlist")
            #expect(newNode.parentId == uuids[3]) // group1 id
        }

        @Test func insert() throws {
            var collection = try create(nodeCount: 2, childrenCount: 2)

            let id = try nextUUID()
            let node = OutlineNode(title: "New Playlist", isEditable: true, symbolName: "playlist", nodeIdentifier: .init(parentId: nil, id: id))
            try collection.insert(node: node, in: uuids[0])

            let newNode = try #require(collection[uuid: id])
            #expect(newNode.title == "New Playlist")
            #expect(newNode.parentId == uuids[0])
        }

        @Test func remove() throws {
            var collection = try create(nodeCount: 2, childrenCount: 2)

            try collection.remove(id: uuids[0])
            #expect(collection.nodes.count == 1)

            // this was the first child of the node just removed, so it should also be gone
            #expect(throws: Error.self) {
                try collection.remove(id: uuids[1])
            }

            // remove the last playlist in Group 1
            try collection.remove(id: uuids[5])

            let group1 = collection.lookup(uuid: uuids[3])
            // should be 1 playlist left
            #expect(group1?.children.count == 1)
        }

        @Test func removeNodes() throws {
            var collection = try create(nodeCount: 2, childrenCount: 2)

            let removedNodes = try collection.remove(nodes: [collection[uuid: uuids[1]]!, collection[uuid: uuids[2]]!])
            #expect(removedNodes.count == 2)

            let group0 = collection.lookup(uuid: uuids[0])
            #expect(group0?.children.count == 0)
        }

        @Test func indexOf() throws {
            let collection = try create(nodeCount: 2, childrenCount: 2)

            #expect(collection.indexOf(node: collection[uuid: uuids[0]]!) == 0) // group 0
            #expect(collection.indexOf(node: collection[uuid: uuids[1]]!) == 0) // playlist 0.0
            #expect(collection.indexOf(node: collection[uuid: uuids[2]]!) == 1) // playlist 0.1

            #expect(collection.indexOf(node: collection[uuid: uuids[3]]!) == 1) // group 1
            #expect(collection.indexOf(node: collection[uuid: uuids[4]]!) == 0) // playlist 1.0
            #expect(collection.indexOf(node: collection[uuid: uuids[5]]!) == 1) // playlist 1.1
        }

        @Test func expanded() throws {
            var collection = try create(nodeCount: 2, childrenCount: 2)

            collection.update(node: collection[uuid: uuids[0]]!, isExpanded: true)
            #expect(collection[uuid: uuids[0]]?.isExpanded == true)

            collection.update(node: collection[uuid: uuids[0]]!, isExpanded: false)
            #expect(collection[uuid: uuids[0]]?.isExpanded == false)
        }

        // MARK: - Error Paths

        @Test func renameNonExistentIdThrows() throws {
            var collection = try create(nodeCount: 1, childrenCount: 1)
            let bogusId = UUID()

            #expect(throws: Error.self) {
                try collection.rename(id: bogusId, title: "Won't Work")
            }
        }

        @Test func updateNonExistentNodeThrows() throws {
            var collection = try create(nodeCount: 1, childrenCount: 1)
            let node = OutlineNode(title: "Ghost", isEditable: true, symbolName: nil, nodeIdentifier: .init(id: UUID()))

            #expect(throws: Error.self) {
                try collection.update(node: node)
            }
        }

        @Test func insertIntoNonExistentParentThrows() throws {
            var collection = try create(nodeCount: 1, childrenCount: 1)
            let bogusParentId = UUID()
            let child = OutlineNode(title: "Orphan", isEditable: true, symbolName: nil, nodeIdentifier: .init(id: UUID()))

            #expect(throws: Error.self) {
                try collection.insert(node: child, in: bogusParentId)
            }
        }

        @Test func removeNonExistentIdThrows() throws {
            var collection = try create(nodeCount: 1, childrenCount: 1)
            let bogusId = UUID()

            #expect(throws: Error.self) {
                try collection.remove(id: bogusId)
            }
        }

        @Test func removeNonExistentIdsThrows() throws {
            var collection = try create(nodeCount: 1, childrenCount: 1)

            #expect(throws: Error.self) {
                try collection.remove(ids: [UUID()])
            }
        }

        // MARK: - Expanded Elements

        @Test func expandedElements() throws {
            var collection = try create(nodeCount: 3, childrenCount: 1)

            #expect(collection.expandedElements.isEmpty)

            collection.update(node: collection[uuid: uuids[0]]!, isExpanded: true)
            collection.update(node: collection[uuid: uuids[2]]!, isExpanded: true)

            let expanded = collection.expandedElements
            #expect(expanded.count == 2)
            #expect(expanded[0].id == uuids[0])
            #expect(expanded[1].id == uuids[2])
        }

        // MARK: - Sort Indexes

        @Test func updateSortIndexes() throws {
            let collection = try create(nodeCount: 3, childrenCount: 2)

            // Top-level sort indexes
            for i in 0 ..< collection.nodes.count {
                #expect(collection.nodes[i].sortIndex == i)
            }

            // Children sort indexes
            for node in collection.nodes {
                for c in 0 ..< node.children.count {
                    #expect(node.children[c].sortIndex == c)
                }
            }
        }

        @Test func sortIndexesUpdateAfterRemoval() throws {
            var collection = try create(nodeCount: 3, childrenCount: 1)

            // Remove the middle group (index 1) via the public batch API which updates sort indexes
            try collection.remove(ids: [uuids[2]])

            // Remaining nodes should have updated sort indexes
            #expect(collection.nodes[0].sortIndex == 0)
            #expect(collection.nodes[1].sortIndex == 1)
        }

        // MARK: - Sort Children

        @Test func sortChildrenAlphabetically() throws {
            var collection = try create(nodeCount: 1, childrenCount: 0)
            let parentId = uuids[0]

            // Insert children in reverse-alphabetical order
            let idC = try nextUUID()
            let idA = try nextUUID()
            let idB = try nextUUID()

            try collection.insert(node: OutlineNode(title: "Cherry", isEditable: true, symbolName: nil, nodeIdentifier: .init(id: idC)), in: parentId)
            try collection.insert(node: OutlineNode(title: "Apple", isEditable: true, symbolName: nil, nodeIdentifier: .init(id: idA)), in: parentId)
            try collection.insert(node: OutlineNode(title: "Banana", isEditable: true, symbolName: nil, nodeIdentifier: .init(id: idB)), in: parentId)

            let parent = try #require(collection[uuid: parentId])
            #expect(parent.children.count == 3)

            try collection.sortChildren(of: parent)

            let sorted = try #require(collection[uuid: parentId])
            #expect(sorted.children[0].title == "Apple")
            #expect(sorted.children[1].title == "Banana")
            #expect(sorted.children[2].title == "Cherry")
        }

        @Test func sortChildrenOfLeafThrows() throws {
            let collection = try create(nodeCount: 1, childrenCount: 1)
            let leaf = try #require(collection[uuid: uuids[1]])

            var mutable = collection
            #expect(throws: Error.self) {
                try mutable.sortChildren(of: leaf)
            }
        }

        // MARK: - Remove All

        @Test func removeAll() throws {
            var collection = try create(nodeCount: 3, childrenCount: 2)
            #expect(collection.count == 3)

            collection.removeAll()
            #expect(collection.count == 0)
            #expect(collection.nodes.isEmpty)
        }

        // MARK: - Batch Lookup

        @Test func lookupUUIDs() throws {
            let collection = try create(nodeCount: 2, childrenCount: 2)

            let results = collection.lookup(uuids: [uuids[1], uuids[4]])
            #expect(results.count == 2)
            #expect(results[0].title == "Playlist 0.0")
            #expect(results[1].title == "Playlist 1.0")
        }

        @Test func lookupUUIDsSkipsMissing() throws {
            let collection = try create(nodeCount: 1, childrenCount: 1)

            let results = collection.lookup(uuids: [uuids[1], UUID()])
            #expect(results.count == 1)
            #expect(results[0].title == "Playlist 0.0")
        }

        @Test func lookupUUIDsEmpty() throws {
            let collection = try create(nodeCount: 1, childrenCount: 1)

            let results = collection.lookup(uuids: [])
            #expect(results.isEmpty)
        }

        // MARK: - Subscript Bounds

        @Test func subscriptIndexBounds() throws {
            let collection = try create(nodeCount: 2, childrenCount: 1)

            #expect(collection[index: 0] != nil)
            #expect(collection[index: 1] != nil)
            #expect(collection[index: 2] == nil)
            #expect(collection[index: -1] == nil)
        }

        @Test func subscriptUUIDMissing() throws {
            let collection = try create(nodeCount: 1, childrenCount: 1)

            #expect(collection[uuid: UUID()] == nil)
        }

        // MARK: - Insert at Index

        @Test func insertAtSpecificIndex() throws {
            var collection = try create(nodeCount: 1, childrenCount: 2)
            let parentId = uuids[0]

            let newId = try nextUUID()
            let node = OutlineNode(title: "Inserted", isEditable: true, symbolName: nil, nodeIdentifier: .init(id: newId))

            try collection.insert(node: node, in: parentId, atIndex: 1)

            let parent = try #require(collection[uuid: parentId])
            #expect(parent.children.count == 3)
            #expect(parent.children[0].title == "Playlist 0.0")
            #expect(parent.children[1].title == "Inserted")
            #expect(parent.children[2].title == "Playlist 0.1")
        }

        @Test func insertMultipleChildren() throws {
            var collection = try create(nodeCount: 1, childrenCount: 1)
            let parentId = uuids[0]

            let id1 = try nextUUID()
            let id2 = try nextUUID()
            let children = [
                OutlineNode(title: "Child A", isEditable: true, symbolName: nil, nodeIdentifier: .init(id: id1)),
                OutlineNode(title: "Child B", isEditable: true, symbolName: nil, nodeIdentifier: .init(id: id2)),
            ]

            let inserted = try collection.insert(nodes: children, in: parentId)
            #expect(inserted.count == 2)

            let parent = try #require(collection[uuid: parentId])
            #expect(parent.children.count == 3)

            // Verify parentId was set on inserted children
            #expect(inserted[0].parentId == parentId)
            #expect(inserted[1].parentId == parentId)
        }

        @Test func insertExpandsParent() throws {
            var collection = try create(nodeCount: 1, childrenCount: 0)
            let parentId = uuids[0]

            #expect(collection[uuid: parentId]?.isExpanded == false)

            let newId = try nextUUID()
            let child = OutlineNode(title: "Child", isEditable: true, symbolName: nil, nodeIdentifier: .init(id: newId))
            try collection.insert(node: child, in: parentId)

            #expect(collection[uuid: parentId]?.isExpanded == true)
        }

        // MARK: - Append Group Nodes

        @Test func appendGroupNodesPreservesExpansion() throws {
            var collection = try create(nodeCount: 2, childrenCount: 1)

            // Expand Group 0
            collection.update(node: collection[uuid: uuids[0]]!, isExpanded: true)
            #expect(collection[uuid: uuids[0]]?.isExpanded == true)

            // Create a new group to append
            let newGroupId = try nextUUID()
            let newGroup = OutlineNode(title: "Group 2", isEditable: true, symbolName: "folder", nodeIdentifier: .init(parentId: nil, id: newGroupId))

            collection.append(groupNodes: [newGroup])

            #expect(collection.count == 3)
            #expect(collection[uuid: newGroupId]?.title == "Group 2")

            // Expansion state of Group 0 should be preserved
            #expect(collection[uuid: uuids[0]]?.isExpanded == true)
        }

        @Test func appendGroupNodesRemovesDuplicates() throws {
            var collection = try create(nodeCount: 2, childrenCount: 1)

            let existingGroup = try #require(collection[uuid: uuids[0]])
            var movedGroup = existingGroup
            movedGroup.title = "Renamed Group 0"

            collection.append(groupNodes: [movedGroup])

            // The node should be at the end now with the new title
            let lastNode = collection.nodes.last
            #expect(lastNode?.id == uuids[0])
            #expect(lastNode?.title == "Renamed Group 0")
        }

        // MARK: - Insert Group Nodes

        @Test func insertGroupNodesAtIndex() throws {
            var collection = try create(nodeCount: 2, childrenCount: 1)

            let newGroupId = try nextUUID()
            let newGroup = OutlineNode(title: "Inserted Group", isEditable: true, symbolName: "folder", nodeIdentifier: .init(parentId: nil, id: newGroupId))

            collection.insert(groupNodes: [newGroup], atIndex: 1)

            #expect(collection.count == 3)
            #expect(collection.nodes[1].title == "Inserted Group")
        }

        @Test func insertGroupNodesFallsBackToAppend() throws {
            var collection = try create(nodeCount: 2, childrenCount: 1)

            let newGroupId = try nextUUID()
            let newGroup = OutlineNode(title: "Appended Group", isEditable: true, symbolName: "folder", nodeIdentifier: .init(parentId: nil, id: newGroupId))

            // Out of bounds index should fall back to append
            collection.insert(groupNodes: [newGroup], atIndex: 999)

            #expect(collection.count == 3)
            #expect(collection.nodes.last?.title == "Appended Group")
        }

        @Test func insertGroupNodesNilIndex() throws {
            var collection = try create(nodeCount: 2, childrenCount: 1)

            let newGroupId = try nextUUID()
            let newGroup = OutlineNode(title: "Nil Index Group", isEditable: true, symbolName: "folder", nodeIdentifier: .init(parentId: nil, id: newGroupId))

            // nil index should append
            collection.insert(groupNodes: [newGroup], atIndex: nil)

            #expect(collection.count == 3)
            #expect(collection.nodes.last?.title == "Nil Index Group")
        }

        // MARK: - indexOf Edge Cases

        @Test func indexOfMissingNode() throws {
            let collection = try create(nodeCount: 1, childrenCount: 1)

            let ghost = OutlineNode(title: "Ghost", isEditable: true, symbolName: nil, nodeIdentifier: .init(id: UUID()))
            #expect(collection.indexOf(node: ghost) == nil)
        }

        @Test func indexOfOrphanedChild() throws {
            let collection = try create(nodeCount: 1, childrenCount: 1)

            // A node whose parentId points to a non-existent parent
            let orphan = OutlineNode(title: "Orphan", isEditable: true, symbolName: nil, nodeIdentifier: .init(parentId: UUID(), id: UUID()))
            #expect(collection.indexOf(node: orphan) == nil)
        }

        // MARK: - Empty Collection

        @Test func emptyCollectionOperations() throws {
            let collection = OutlineNodeCollection()

            #expect(collection.count == 0)
            #expect(collection.nodes.isEmpty)
            #expect(collection.expandedElements.isEmpty)
            #expect(collection[index: 0] == nil)
            #expect(collection[uuid: UUID()] == nil)
            #expect(collection.lookup(uuid: UUID()) == nil)
            #expect(collection.lookup(uuids: [UUID()]).isEmpty)
        }

        // MARK: - Codable Round-Trip

        @Test func codableRoundTrip() throws {
            var collection = try create(nodeCount: 2, childrenCount: 3)

            // Set some state to verify round-trip fidelity
            collection.update(node: collection[uuid: uuids[0]]!, isExpanded: true)

            let data = try JSONEncoder().encode(collection)
            let decoded = try JSONDecoder().decode(OutlineNodeCollection.self, from: data)

            #expect(decoded.count == collection.count)
            #expect(decoded.nodes[0].title == "Group 0")
            #expect(decoded.nodes[0].isExpanded == true)
            #expect(decoded.nodes[1].isExpanded == false)

            // Verify children round-trip
            #expect(decoded.nodes[0].children.count == 3)
            #expect(decoded.nodes[0].children[0].title == "Playlist 0.0")
            #expect(decoded.nodes[0].children[0].parentId == uuids[0])
        }

        @Test func codableRoundTripEmptyCollection() throws {
            let collection = OutlineNodeCollection()

            let data = try JSONEncoder().encode(collection)
            let decoded = try JSONDecoder().decode(OutlineNodeCollection.self, from: data)

            #expect(decoded.count == 0)
            #expect(decoded.nodes.isEmpty)
        }

        // MARK: - NodeIdentifier Previous Parent Tracking

        @Test func nodeIdentifierTracksPreviousParent() throws {
            var collection = try create(nodeCount: 2, childrenCount: 1)

            // Move child from Group 0 to Group 1
            let child = try #require(collection[uuid: uuids[1]])
            #expect(child.nodeIdentifier.previousParentId == nil)

            try collection.remove(id: uuids[1])
            let moved = try collection.insert(node: child, in: uuids[2])

            #expect(moved.parentId == uuids[2])
            #expect(moved.nodeIdentifier.previousParentId == uuids[0])
        }
    }

#endif
