// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)

    import AppKit
    import Foundation

    public enum OutlineEditOperation: Sendable {
        case move(source: [OutlineNode], destination: [OutlineNode])
        case copy(source: [OutlineNode], destination: [OutlineNode])
        case renamed(source: OutlineNode, destination: OutlineNode)
        case removed(nodes: [OutlineNode])
        case sort(nodes: [OutlineNode])
        /// `operation` is the drop's resolved drag operation, carried so a handler can tell a
        /// move from an Option-held copy. Modifier keys narrow it before it reaches here, so a
        /// value of exactly `.copy` means the user asked for a copy.
        case append(urls: [URL], destination: OutlineNode?, atIndex: Int?, operation: NSDragOperation)
        /// Fired after a group drag completes. `groups` is the full ordered list of
        /// top-level nodes reflecting the new group order.
        case reorderGroups(groups: [OutlineNode])
    }

#endif
