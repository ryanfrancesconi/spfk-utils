// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

public struct Counter: Sendable {
    var identifier: Int

    public init(startingValue identifier: Int = 0) {
        self.identifier = identifier
    }

    public mutating func next() -> Int {
        identifier += 1
        return identifier
    }

    public mutating func reset() {
        identifier = 0
    }
}
