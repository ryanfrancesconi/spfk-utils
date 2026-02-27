// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
    import Foundation
    import Numerics
    import SPFKTesting
    import Testing

    @testable import SPFKUtils

    final class OutlineNodeTests: TestCaseModel {
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

            let node = OutlineNode(title: "New Playlist", isEditable: true, symbolName: "playlist", nodeIdentifier: .init(parentId: nil, id: uuids[5]))

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
    }

#endif
