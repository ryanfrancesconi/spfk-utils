import Foundation

public enum OutlineEditOperation: Sendable {
    case move(source: [OutlineNode], destination: [OutlineNode])
    case copy(source: [OutlineNode], destination: [OutlineNode])
    
    case renamed(node: OutlineNode)
    case removed(nodes: [OutlineNode])
}
