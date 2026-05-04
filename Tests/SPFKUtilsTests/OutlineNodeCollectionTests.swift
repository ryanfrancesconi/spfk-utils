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

        // MARK: - Drag Drop Index Adjustment

        // Exercises the full drag pipeline: given NSOutlineView's proposedChildIndex
        // (pre-removal coordinate), compute adjustedAtIndex, then call insert(groupNodes:atIndex:).
        // The adjustment formula: adjustedAtIndex = proposedChildIndex - count(dragged nodes
        // whose current index < proposedChildIndex).
        @Test func dragDropIndexAdjustment() throws {
            func adjusted(proposedChildIndex: Int, draggedIndex: Int) -> Int {
                let removedBefore = draggedIndex < proposedChildIndex ? 1 : 0
                return max(0, proposedChildIndex - removedBefore)
            }

            func check(proposed: Int, draggedIndex: Int, expectedOrder: [Int], file: String = #filePath, line: Int = #line) throws {
                var collection = try createFourGroups()
                let ids = collection.nodes.map(\.id)
                let dragged = collection.nodes[draggedIndex]
                collection.insert(groupNodes: [dragged], atIndex: adjusted(proposedChildIndex: proposed, draggedIndex: draggedIndex))
                #expect(collection.nodes.map(\.id) == expectedOrder.map { ids[$0] }, sourceLocation: .init(fileID: file, filePath: file, line: line, column: 1))
            }

            // [G0, G1, G2, G3]
            // drag G2 (index=2) to front: proposed=0, removedBefore=0, adjusted=0 → [G2,G0,G1,G3]
            try check(proposed: 0, draggedIndex: 2, expectedOrder: [2, 0, 1, 3])
            // drag G1 (index=1) past G2: proposed=3, removedBefore=1, adjusted=2 → [G0,G2,G1,G3]
            try check(proposed: 3, draggedIndex: 1, expectedOrder: [0, 2, 1, 3])
            // drag G0 (index=0) to end: proposed=4, removedBefore=1, adjusted=3 → [G1,G2,G3,G0]
            try check(proposed: 4, draggedIndex: 0, expectedOrder: [1, 2, 3, 0])
            // drag G2 (index=2) to end: proposed=4, removedBefore=1, adjusted=3 → [G0,G1,G3,G2]
            try check(proposed: 4, draggedIndex: 2, expectedOrder: [0, 1, 3, 2])
            // drag G3 (index=3) one step back: proposed=2, removedBefore=0, adjusted=2 → [G0,G1,G3,G2]
            try check(proposed: 2, draggedIndex: 3, expectedOrder: [0, 1, 3, 2])
            // drag G3 (index=3) to second slot: proposed=1, removedBefore=0, adjusted=1 → [G0,G3,G1,G2]
            try check(proposed: 1, draggedIndex: 3, expectedOrder: [0, 3, 1, 2])
        }

        // MARK: - Leaf Reorder (Move Existing within same group)

        // These tests cover the remove-then-insert offset for leaf nodes.
        // NSOutlineView reports childIndex in pre-removal coordinates. The drag handler
        // must subtract the count of same-group nodes being removed whose index < childIndex.

        @Test func leafReorderForwardOneStep() throws {
            // [C0, C1, C2] → drag C0 to between C1 and C2 (proposed childIndex=2)
            // C0 is at index 0, which is < 2 → removedBefore=1, adjustedIndex=1
            // Expected: [C1, C0, C2]
            var collection = try create(nodeCount: 1, childrenCount: 3)
            let parentId = uuids[0]
            let c0id = uuids[1], c1id = uuids[2], c2id = uuids[3]

            let c0 = try #require(collection[uuid: c0id])
            let removedBefore = [c0].filter { $0.parentId == parentId }
                .compactMap { collection.indexOf(node: $0) }
                .filter { $0 < 2 }.count
            let adjustedIndex = max(0, 2 - removedBefore)

            try collection.remove(nodes: [c0])
            try collection.insert(nodes: [c0], in: parentId, atIndex: adjustedIndex)

            let parent = try #require(collection[uuid: parentId])
            #expect(parent.children[0].id == c1id)
            #expect(parent.children[1].id == c0id)
            #expect(parent.children[2].id == c2id)
        }

        @Test func leafReorderBackwardOneStep() throws {
            // [C0, C1, C2] → drag C2 to between C0 and C1 (proposed childIndex=1)
            // C2 is at index 2, which is NOT < 1 → removedBefore=0, adjustedIndex=1
            // Expected: [C0, C2, C1]
            var collection = try create(nodeCount: 1, childrenCount: 3)
            let parentId = uuids[0]
            let c0id = uuids[1], c1id = uuids[2], c2id = uuids[3]

            let c2 = try #require(collection[uuid: c2id])
            let removedBefore = [c2].filter { $0.parentId == parentId }
                .compactMap { collection.indexOf(node: $0) }
                .filter { $0 < 1 }.count
            let adjustedIndex = max(0, 1 - removedBefore)

            try collection.remove(nodes: [c2])
            try collection.insert(nodes: [c2], in: parentId, atIndex: adjustedIndex)

            let parent = try #require(collection[uuid: parentId])
            #expect(parent.children[0].id == c0id)
            #expect(parent.children[1].id == c2id)
            #expect(parent.children[2].id == c1id)
        }

        // MARK: - Group Reorder (Move Existing)

        // These tests cover moving a group that is ALREADY in the collection to a new position.
        // The input `atIndex` is the pre-adjusted value that the drag handler computes
        // (rawProposedChildIndex minus the count of dragged nodes whose current index is
        // before the target). The collection's remove-then-insert must land the node at the
        // correct final position.

        // Helper: 4 groups with no children.
        // uuids[0]=G0, uuids[1]=G1, uuids[2]=G2, uuids[3]=G3
        func createFourGroups() throws -> OutlineNodeCollection {
            try create(nodeCount: 4, childrenCount: 0)
        }

        @Test func reorderMoveBackwardToFront() throws {
            // [G0, G1, G2, G3] → drag G2 to front (proposedChildIndex=0, adjustedAtIndex=0)
            // G2's index (2) >= 0, so no adjustment → adjustedAtIndex = 0
            // Expected: [G2, G0, G1, G3]
            var collection = try createFourGroups()
            let g2 = try #require(collection[uuid: uuids[2]])

            collection.insert(groupNodes: [g2], atIndex: 0)

            #expect(collection.nodes[0].id == uuids[2])
            #expect(collection.nodes[1].id == uuids[0])
            #expect(collection.nodes[2].id == uuids[1])
            #expect(collection.nodes[3].id == uuids[3])
        }

        @Test func reorderMoveBackwardOneStep() throws {
            // [G0, G1, G2, G3] → drag G2 to before G1 (proposedChildIndex=1, adjustedAtIndex=1)
            // G2's index (2) >= 1 → adjustedAtIndex = 1
            // Expected: [G0, G2, G1, G3]
            var collection = try createFourGroups()
            let g2 = try #require(collection[uuid: uuids[2]])

            collection.insert(groupNodes: [g2], atIndex: 1)

            #expect(collection.nodes[0].id == uuids[0])
            #expect(collection.nodes[1].id == uuids[2])
            #expect(collection.nodes[2].id == uuids[1])
            #expect(collection.nodes[3].id == uuids[3])
        }

        @Test func reorderMoveForwardOneStep() throws {
            // [G0, G1, G2, G3] → drag G1 to between G2 and G3 (proposedChildIndex=3)
            // G1's index (1) < 3 → adjustedAtIndex = 3 - 1 = 2
            // Expected: [G0, G2, G1, G3]
            var collection = try createFourGroups()
            let g1 = try #require(collection[uuid: uuids[1]])

            collection.insert(groupNodes: [g1], atIndex: 2)

            #expect(collection.nodes[0].id == uuids[0])
            #expect(collection.nodes[1].id == uuids[2])
            #expect(collection.nodes[2].id == uuids[1])
            #expect(collection.nodes[3].id == uuids[3])
        }

        @Test func reorderMoveForwardToEnd() throws {
            // [G0, G1, G2, G3] → drag G0 to end (proposedChildIndex=4)
            // G0's index (0) < 4 → adjustedAtIndex = 4 - 1 = 3
            // Expected: [G1, G2, G3, G0]
            var collection = try createFourGroups()
            let g0 = try #require(collection[uuid: uuids[0]])

            collection.insert(groupNodes: [g0], atIndex: 3)

            #expect(collection.nodes[0].id == uuids[1])
            #expect(collection.nodes[1].id == uuids[2])
            #expect(collection.nodes[2].id == uuids[3])
            #expect(collection.nodes[3].id == uuids[0])
        }

        @Test func reorderSortIndexesUpdatedAfterMove() throws {
            // After a reorder, sortIndexes must reflect new positions.
            var collection = try createFourGroups()
            let g3 = try #require(collection[uuid: uuids[3]])

            collection.insert(groupNodes: [g3], atIndex: 0) // move last to front

            for i in 0 ..< collection.nodes.count {
                #expect(collection.nodes[i].sortIndex == i)
            }
        }

        @Test func reorderExpandedStatePreservedAfterMove() throws {
            // Expanded state must survive a reorder.
            // [G0, G1, G2, G3] → drag G1 to end (proposedChildIndex=4, adjustedAtIndex=3)
            var collection = try createFourGroups()
            collection.update(node: collection[uuid: uuids[1]]!, isExpanded: true)

            let g1 = try #require(collection[uuid: uuids[1]])
            collection.insert(groupNodes: [g1], atIndex: 3)

            #expect(collection[uuid: uuids[1]]?.isExpanded == true)
        }

        @Test func reorderPreservesExpansionOfNonDraggedGroups() throws {
            // A group that is NOT being dragged must keep its expanded state.
            // Regression: if the drag handler captures nodeState after spring-loading
            // has mutated data, non-dragged groups can lose their expansion.
            // [G0(expanded), G1, G2, G3] → drag G2 to position 1
            // G0 must still be expanded after the insert.
            var collection = try createFourGroups()
            collection.update(node: collection[uuid: uuids[0]]!, isExpanded: true)

            let g2 = try #require(collection[uuid: uuids[2]])
            collection.insert(groupNodes: [g2], atIndex: 1)

            // G2 should be at position 1
            #expect(collection.nodes[1].id == uuids[2])
            // G0 must still be expanded
            #expect(collection[uuid: uuids[0]]?.isExpanded == true)
            // G2 (dragged) should not have been auto-expanded
            #expect(collection[uuid: uuids[2]]?.isExpanded == false)
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
