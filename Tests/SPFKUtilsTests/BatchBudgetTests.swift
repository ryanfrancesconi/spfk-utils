// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
@testable import SPFKUtils
import Testing

@Suite(.serialized) struct BatchBudgetTests {
    private final class InFlight: @unchecked Sendable {
        private let lock = NSLock()
        private var current = 0
        private(set) var highest = 0

        func enter() { lock.withLock { current += 1; highest = max(highest, current) } }
        func leave() { lock.withLock { current -= 1 } }
    }

    private final class Done: @unchecked Sendable {
        private let lock = NSLock()
        private var value: Int?
        var count: Int? { lock.withLock { value } }
        func set(_ count: Int) { lock.withLock { value = count } }
    }

    private static func batch(_ budget: BatchBudget, count: Int, width: Int, inFlight: InFlight) async {
        let lease = BatchBudget.Lease()
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< width {
                group.addTask {
                    for _ in 0 ..< count / width {
                        await budget.withSlot(lease) {
                            inFlight.enter()
                            try? await Task.sleep(for: .milliseconds(5))
                            inFlight.leave()
                        }
                    }
                }
            }
        }
    }

    @Test func twoBatchesTogetherStayWithinTheBudgetPlusOne() async {
        let budget = BatchBudget(4)
        let inFlight = InFlight()

        async let first: Void = Self.batch(budget, count: 60, width: 6, inFlight: inFlight)
        async let second: Void = Self.batch(budget, count: 60, width: 6, inFlight: inFlight)
        _ = await (first, second)

        // One over only while a batch with nothing running would otherwise wait.
        #expect(inFlight.highest <= 5)
    }

    @Test func oneBatchWithinTheBudgetRunsAtItsFullWidth() async {
        let budget = BatchBudget(8)
        let inFlight = InFlight()
        await Self.batch(budget, count: 60, width: 6, inFlight: inFlight)
        #expect(inFlight.highest == 6)
    }

    @Test func aBatchInsideAnItemDoesNotWaitForSlots() async throws {
        // Every slot is held by an outer item, each of which runs a batch of its own.
        let width = BatchBudget.shared.capacity
        let results = try await batchMap(count: width, batchSize: width) { i -> Int? in
            let inner = try await batchMap(count: 4, batchSize: 4) { j -> Int? in j }
            return i + inner.count
        }
        #expect(results.count == width)
    }

    @Test func aBatchStartedFromADetachedTaskInsideAnItemStillFinishes() async throws {
        // A detached task does not inherit the nesting mark, so the inner batch competes for
        // slots every outer item holds while waiting on it.
        let width = BatchBudget.shared.capacity
        let done = Done()
        _ = Task {
            let results = try await batchMap(count: width, batchSize: width) { i -> Int? in
                let inner = try await Task.detached {
                    try await batchMap(count: 4, batchSize: 4) { j -> Int? in j }.count
                }.value
                return i + inner
            }
            done.set(results.count)
        }

        // A deadlocked batch never returns, so poll rather than await it.
        let deadline = Date().addingTimeInterval(10)
        while done.count == nil, Date() < deadline {
            try await Task.sleep(for: .milliseconds(50))
        }
        #expect(done.count == width)
    }
}
