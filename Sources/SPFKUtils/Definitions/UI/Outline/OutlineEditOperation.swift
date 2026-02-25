import Foundation

public enum OutlineEditOperation: Sendable {
    case move(source: [OutlineNode], destination: [OutlineNode])
    case copy(source: [OutlineNode], destination: [OutlineNode])
    case renamed(source: OutlineNode, destination: OutlineNode)
    case removed(nodes: [OutlineNode])
    case sort(nodes: [OutlineNode])
    case append(urls: [URL], destination: OutlineNode)
}
