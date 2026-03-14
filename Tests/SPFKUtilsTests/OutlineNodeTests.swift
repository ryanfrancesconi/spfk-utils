// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
    import Foundation
    import SPFKBase
    import SPFKTesting
    import Testing

    @testable import SPFKUtils

    // MARK: - OutlineNode Tests

    @Suite
    final class OutlineNodeTests: TestCaseModel {

        // MARK: - Computed Properties

        @Test func isLeafRequiresParentAndNoChildren() {
            let parentId = UUID()
            let leaf = OutlineNode(title: "Leaf", isEditable: true, symbolName: nil, nodeIdentifier: .init(parentId: parentId, id: UUID()))

            #expect(leaf.isLeaf == true)
            #expect(leaf.hasChildren == false)
        }

        @Test func groupWithChildrenIsNotLeaf() {
            let groupId = UUID()
            let child = OutlineNode(title: "Child", isEditable: true, symbolName: nil, nodeIdentifier: .init(parentId: groupId, id: UUID()))
            let group = OutlineNode(title: "Group", isEditable: true, symbolName: "folder", nodeIdentifier: .init(id: groupId), children: [child])

            #expect(group.isLeaf == false)
            #expect(group.hasChildren == true)
        }

        @Test func topLevelNodeWithNoChildrenIsNotLeaf() {
            // parentId is nil and children is empty — isLeaf requires parentId != nil
            let node = OutlineNode(title: "Lonely", isEditable: true, symbolName: nil, nodeIdentifier: .init(id: UUID()))

            #expect(node.isLeaf == false)
            #expect(node.hasChildren == false)
        }

        @Test func topLevelNodeWithChildrenIsNotLeaf() {
            let groupId = UUID()
            let child = OutlineNode(title: "Child", isEditable: true, symbolName: nil, nodeIdentifier: .init(parentId: groupId, id: UUID()))
            let group = OutlineNode(title: "Group", isEditable: true, symbolName: nil, nodeIdentifier: .init(id: groupId), children: [child])

            #expect(group.isLeaf == false)
            #expect(group.hasChildren == true)
        }

        // MARK: - Identifier

        @Test func identifierForLeaf() {
            let leaf = OutlineNode(title: "Leaf", isEditable: true, symbolName: nil, nodeIdentifier: .init(parentId: UUID(), id: UUID()))

            #expect(leaf.identifier.rawValue == "OutlineNodeLeaf")
        }

        @Test func identifierForGroup() {
            let groupId = UUID()
            let child = OutlineNode(title: "Child", isEditable: true, symbolName: nil, nodeIdentifier: .init(parentId: groupId, id: UUID()))
            let group = OutlineNode(title: "Group", isEditable: true, symbolName: nil, nodeIdentifier: .init(id: groupId), children: [child])

            #expect(group.identifier.rawValue == "OutlineNodeGroup")
        }

        @Test func identifierForTopLevelEmptyNode() {
            // No parentId, no children — not a leaf, so "OutlineNodeGroup"
            let node = OutlineNode(title: "Empty", isEditable: true, symbolName: nil, nodeIdentifier: .init(id: UUID()))

            #expect(node.identifier.rawValue == "OutlineNodeGroup")
        }

        // MARK: - Child Subscript

        @Test func childSubscriptValidIndex() {
            let groupId = UUID()
            let children = (0 ..< 3).map { i in
                OutlineNode(title: "Child \(i)", isEditable: true, symbolName: nil, nodeIdentifier: .init(parentId: groupId, id: UUID()))
            }
            let group = OutlineNode(title: "Group", isEditable: true, symbolName: nil, nodeIdentifier: .init(id: groupId), children: children)

            #expect(group[childIndex: 0]?.title == "Child 0")
            #expect(group[childIndex: 1]?.title == "Child 1")
            #expect(group[childIndex: 2]?.title == "Child 2")
        }

        @Test func childSubscriptOutOfBounds() {
            let group = OutlineNode(title: "Group", isEditable: true, symbolName: nil, nodeIdentifier: .init(id: UUID()))

            #expect(group[childIndex: 0] == nil)
            #expect(group[childIndex: -1] == nil)
            #expect(group[childIndex: 999] == nil)
        }

        // MARK: - titleAndID

        @Test func titleAndID() {
            let id = UUID()
            let node = OutlineNode(title: "My Node", isEditable: true, symbolName: nil, nodeIdentifier: .init(id: id))

            #expect(node.titleAndID == "My Node (\(id))")
        }

        // MARK: - Equality

        @Test func equalityBasedOnNodeIdentifierOnly() {
            let id = UUID()

            let a = OutlineNode(title: "Title A", isEditable: true, symbolName: "folder", nodeIdentifier: .init(id: id))
            let b = OutlineNode(title: "Title B", isEditable: false, symbolName: nil, nodeIdentifier: .init(id: id))

            // Same nodeIdentifier → equal, despite different title/isEditable/symbolName
            #expect(a == b)
        }

        @Test func inequalityDifferentId() {
            let a = OutlineNode(title: "Same", isEditable: true, symbolName: nil, nodeIdentifier: .init(id: UUID()))
            let b = OutlineNode(title: "Same", isEditable: true, symbolName: nil, nodeIdentifier: .init(id: UUID()))

            #expect(a != b)
        }

        @Test func inequalityDifferentParentId() {
            let id = UUID()

            let a = OutlineNode(title: "Same", isEditable: true, symbolName: nil, nodeIdentifier: .init(parentId: UUID(), id: id))
            let b = OutlineNode(title: "Same", isEditable: true, symbolName: nil, nodeIdentifier: .init(parentId: UUID(), id: id))

            #expect(a != b)
        }

        // MARK: - Duplicate

        @Test func duplicateCreatesNewIdAndPrefixesTitle() {
            let parentId = UUID()
            let original = OutlineNode(title: "Beat", isEditable: true, symbolName: "waveform", hexColor: HexColor(string: "FF0000"), nodeIdentifier: .init(parentId: parentId, id: UUID()))

            let copy = original.duplicate()

            #expect(copy.id != original.id)
            #expect(copy.title == "Copy of Beat")
            #expect(copy.parentId == parentId)
            #expect(copy.isEditable == original.isEditable)
            #expect(copy.symbolName == original.symbolName)
            #expect(copy.hexColor == original.hexColor)
            #expect(copy.nodeIdentifier.originalId == original.id)
        }

        @Test func duplicatePreservesChildren() {
            let groupId = UUID()
            let child = OutlineNode(title: "Child", isEditable: true, symbolName: nil, nodeIdentifier: .init(parentId: groupId, id: UUID()))
            let group = OutlineNode(title: "Group", isEditable: true, symbolName: "folder", nodeIdentifier: .init(id: groupId), children: [child])

            let copy = group.duplicate()

            #expect(copy.children.count == 1)
            // Children are shallow-copied (same child objects)
            #expect(copy.children[0].id == child.id)
        }

        @Test func duplicateArrayOfNodes() {
            let nodes = (0 ..< 3).map { i in
                OutlineNode(title: "Node \(i)", isEditable: true, symbolName: nil, nodeIdentifier: .init(parentId: UUID(), id: UUID()))
            }

            let copies = nodes.duplicate()

            #expect(copies.count == 3)
            for i in 0 ..< 3 {
                #expect(copies[i].id != nodes[i].id)
                #expect(copies[i].title == "Copy of Node \(i)")
                #expect(copies[i].nodeIdentifier.originalId == nodes[i].id)
            }
        }

        // MARK: - Codable Round-Trip

        @Test func codableRoundTrip() throws {
            let parentId = UUID()
            let childId = UUID()
            let groupId = UUID()

            let child = OutlineNode(
                title: "Playlist",
                isEditable: false,
                symbolName: "music.note",
                hexColor: HexColor(string: "FF0000"),
                nodeIdentifier: .init(parentId: groupId, id: childId)
            )

            var group = OutlineNode(
                title: "My Group",
                isEditable: true,
                symbolName: "folder",
                nodeIdentifier: .init(parentId: parentId, id: groupId),
                children: [child]
            )
            group.isExpanded = true
            group.sortIndex = 3

            let data = try JSONEncoder().encode(group)
            let decoded = try JSONDecoder().decode(OutlineNode.self, from: data)

            #expect(decoded.title == "My Group")
            #expect(decoded.isEditable == true)
            #expect(decoded.symbolName == "folder")
            #expect(decoded.hexColor == nil) // hexColor is on the child, not the group
            #expect(decoded.isExpanded == true)
            #expect(decoded.sortIndex == 3)
            #expect(decoded.id == groupId)
            #expect(decoded.parentId == parentId)
            #expect(decoded.children.count == 1)

            let decodedChild = decoded.children[0]
            #expect(decodedChild.title == "Playlist")
            #expect(decodedChild.isEditable == false)
            #expect(decodedChild.symbolName == "music.note")
            #expect(decodedChild.hexColor == HexColor(string: "FF0000"))
            #expect(decodedChild.id == childId)
            #expect(decodedChild.parentId == groupId)
        }

        @Test func codableDecodesWithMissingOptionalFields() throws {
            // Minimal JSON — only title and nodeIdentifier
            let id = UUID()
            let json = """
            {
                "title": "Minimal",
                "nodeIdentifier": { "id": "\(id.uuidString)" }
            }
            """

            let decoded = try JSONDecoder().decode(OutlineNode.self, from: Data(json.utf8))

            #expect(decoded.title == "Minimal")
            #expect(decoded.id == id)
            #expect(decoded.isEditable == true)
            #expect(decoded.children.isEmpty)
            #expect(decoded.isExpanded == false)
            #expect(decoded.symbolName == nil)
            #expect(decoded.sortIndex == nil)
            #expect(decoded.hexColor == nil)
            #expect(decoded.parentId == nil)
        }

        @Test func codableThrowsForEmptyContainer() throws {
            // SwiftData empty container scenario — empty JSON object
            let json = "{}"

            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(OutlineNode.self, from: Data(json.utf8))
            }
        }

        @Test func codableDecodesWithTitleOnlyNoNodeIdentifier() throws {
            // title present but no nodeIdentifier — should succeed with generated UUID
            let json = """
            { "title": "Title Only" }
            """

            let decoded = try JSONDecoder().decode(OutlineNode.self, from: Data(json.utf8))
            #expect(decoded.title == "Title Only")
            // nodeIdentifier gets a default UUID — just verify it's non-nil
            #expect(decoded.id != UUID()) // extremely unlikely to collide
        }

        @Test func codableDecodesWithNodeIdentifierOnlyNoTitle() throws {
            // nodeIdentifier present but no title — should succeed with empty title
            let id = UUID()
            let json = """
            { "nodeIdentifier": { "id": "\(id.uuidString)" } }
            """

            let decoded = try JSONDecoder().decode(OutlineNode.self, from: Data(json.utf8))
            #expect(decoded.title == "")
            #expect(decoded.id == id)
        }
    }

    // MARK: - NodeIdentifier Tests

    @Suite
    final class NodeIdentifierTests: TestCaseModel {

        // MARK: - Init

        @Test func initWithDefaults() {
            let id = UUID()
            let identifier = NodeIdentifier(id: id)

            #expect(identifier.id == id)
            #expect(identifier.parentId == nil)
            #expect(identifier.originalId == nil)
            #expect(identifier.previousParentId == nil)
        }

        @Test func initWithParentId() {
            let id = UUID()
            let parentId = UUID()
            let identifier = NodeIdentifier(parentId: parentId, id: id)

            #expect(identifier.id == id)
            #expect(identifier.parentId == parentId)
        }

        // MARK: - Equality

        @Test func equalitySameIdAndParent() {
            let id = UUID()
            let parentId = UUID()

            let a = NodeIdentifier(parentId: parentId, id: id)
            let b = NodeIdentifier(parentId: parentId, id: id)

            #expect(a == b)
        }

        @Test func inequalityDifferentId() {
            let a = NodeIdentifier(id: UUID())
            let b = NodeIdentifier(id: UUID())

            #expect(a != b)
        }

        @Test func inequalityDifferentParentId() {
            let id = UUID()

            let a = NodeIdentifier(parentId: UUID(), id: id)
            let b = NodeIdentifier(parentId: UUID(), id: id)

            #expect(a != b)
        }

        @Test func equalityIgnoresOriginalIdAndPreviousParentId() {
            let id = UUID()
            var a = NodeIdentifier(id: id)
            var b = NodeIdentifier(id: id)

            a.originalId = UUID()
            b.originalId = UUID()

            // originalId and previousParentId are not part of ==
            #expect(a == b)
        }

        // MARK: - Previous Parent Tracking

        @Test func previousParentIdTracksChanges() {
            let parent1 = UUID()
            let parent2 = UUID()
            var identifier = NodeIdentifier(parentId: parent1, id: UUID())

            #expect(identifier.previousParentId == nil)

            identifier.parentId = parent2
            #expect(identifier.previousParentId == parent1)
            #expect(identifier.parentId == parent2)
        }

        @Test func previousParentIdTracksMultipleChanges() {
            let parent1 = UUID()
            let parent2 = UUID()
            let parent3 = UUID()

            var identifier = NodeIdentifier(parentId: parent1, id: UUID())

            identifier.parentId = parent2
            #expect(identifier.previousParentId == parent1)

            identifier.parentId = parent3
            #expect(identifier.previousParentId == parent2)
        }

        @Test func previousParentIdFromNonNilToNil() {
            let parent = UUID()
            var identifier = NodeIdentifier(parentId: parent, id: UUID())

            identifier.parentId = nil
            #expect(identifier.previousParentId == parent)
            #expect(identifier.parentId == nil)
        }

        @Test func previousParentIdFromNilToNonNil() {
            var identifier = NodeIdentifier(id: UUID())

            #expect(identifier.previousParentId == nil)

            let parent = UUID()
            identifier.parentId = parent
            #expect(identifier.previousParentId == nil) // was nil before
            #expect(identifier.parentId == parent)
        }

        // MARK: - Description

        @Test func description() {
            let id = UUID()
            let parentId = UUID()
            let identifier = NodeIdentifier(parentId: parentId, id: id)

            let desc = identifier.description
            #expect(desc.contains(id.uuidString))
            #expect(desc.contains(parentId.uuidString))
            #expect(desc.contains("originalId: nil"))
            #expect(desc.contains("previousParentId: nil"))
        }

        // MARK: - Codable

        @Test func codableRoundTrip() throws {
            let id = UUID()
            let parentId = UUID()
            let identifier = NodeIdentifier(parentId: parentId, id: id)

            let data = try JSONEncoder().encode(identifier)
            let decoded = try JSONDecoder().decode(NodeIdentifier.self, from: data)

            #expect(decoded.id == id)
            #expect(decoded.parentId == parentId)
        }

        @Test func codableRoundTripNilParent() throws {
            let id = UUID()
            let identifier = NodeIdentifier(id: id)

            let data = try JSONEncoder().encode(identifier)
            let decoded = try JSONDecoder().decode(NodeIdentifier.self, from: data)

            #expect(decoded.id == id)
            #expect(decoded.parentId == nil)
        }

        @Test func codableOmitsTransientFields() throws {
            var identifier = NodeIdentifier(parentId: UUID(), id: UUID())
            identifier.originalId = UUID()
            identifier.parentId = UUID() // triggers previousParentId

            let data = try JSONEncoder().encode(identifier)
            let decoded = try JSONDecoder().decode(NodeIdentifier.self, from: data)

            // originalId and previousParentId are not encoded
            #expect(decoded.originalId == nil)
            #expect(decoded.previousParentId == nil)
        }

        @Test func codableThrowsForEmptyContainer() throws {
            let json = "{}"

            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(NodeIdentifier.self, from: Data(json.utf8))
            }
        }

        @Test func codableThrowsForMissingId() throws {
            let json = """
            { "parentId": "\(UUID().uuidString)" }
            """

            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(NodeIdentifier.self, from: Data(json.utf8))
            }
        }
    }

#endif
