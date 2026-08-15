// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

public struct NavigationHistory {
    private var entries: [[OutlineNode]] = []
    private(set) var index: Int = -1

    public init() {}

    public var canGoBack: Bool { index > 0 }
    public var canGoForward: Bool { index < entries.count - 1 }

    /// Discards every entry. Required when the node tree is replaced wholesale — the retained
    /// entries name nodes that no longer exist.
    public mutating func clear() {
        entries.removeAll()
        index = -1
    }

    public mutating func append(_ nodes: [OutlineNode]) {
        if index < entries.count - 1 {
            entries.removeSubrange((index + 1)...)
        }
        entries.append(nodes)
        index = entries.count - 1
    }

    public mutating func back() -> [OutlineNode]? {
        guard canGoBack else { return nil }
        index -= 1
        return entries[index]
    }

    public mutating func forward() -> [OutlineNode]? {
        guard canGoForward else { return nil }
        index += 1
        return entries[index]
    }
}
