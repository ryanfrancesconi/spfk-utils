// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)

    import Foundation

    public enum OutlineEditOperation: Sendable {
        case move(source: [OutlineNode], destination: [OutlineNode])
        case copy(source: [OutlineNode], destination: [OutlineNode])
        case renamed(source: OutlineNode, destination: OutlineNode)
        case removed(nodes: [OutlineNode])
        case sort(nodes: [OutlineNode])
        case append(urls: [URL], destination: OutlineNode?, atIndex: Int?)
        /// Fired after a group drag completes. `groups` is the full ordered list of
        /// top-level nodes reflecting the new group order.
        case reorderGroups(groups: [OutlineNode])
    }

#endif
