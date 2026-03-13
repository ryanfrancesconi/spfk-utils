// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKBase

/// Tracks a collection of items based on index/total
public actor ProgressTracker {
    public private(set) var total: Int
    public private(set) var index: Int = 0
    public private(set) var progress: UnitInterval = 0

    public var description: String {
        "\(index)/\(total)"
    }

    public init(total: Int) {
        self.total = total
    }

    public func increment() -> UnitInterval {
        guard total > 0 else { return 0 }

        guard index < total else { return 1 }

        index += 1
        progress = index.double / total.double

        return progress
    }
}
