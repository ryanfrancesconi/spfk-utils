import Foundation

public struct Counter: Sendable {
    var identifier: Int = -1

    public init(startingValue identifier: Int = -1) {
        self.identifier = identifier
    }

    public mutating func next() -> Int {
        identifier += 1
        return identifier
    }

    public mutating func reset() {
        identifier = -1
    }
}
