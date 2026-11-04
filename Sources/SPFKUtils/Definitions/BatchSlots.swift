// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// Caps how many items of one kind run at once inside a wider batch, such as renders among saves.
///
/// Every ``acquire()`` must be paired with one ``release()``. Waiting ignores cancellation, so an
/// item that has started is never left half done.
public actor BatchSlots {
    private var available: Int
    private var waiting: [CheckedContinuation<Void, Never>] = []

    public init(_ count: Int) {
        available = max(1, count)
    }

    public func acquire() async {
        guard available == 0 else {
            available -= 1
            return
        }

        await withCheckedContinuation { waiting.append($0) }
    }

    public func release() {
        if waiting.isEmpty {
            available += 1
        } else {
            waiting.removeFirst().resume()
        }
    }
}
