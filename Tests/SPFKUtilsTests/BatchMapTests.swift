// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKUtils
import Testing

final class BatchMapTests {
    // MARK: - Basic Functionality

    @Test func returnsAllResults() async throws {
        let results = try await batchMap(count: 5, batchSize: 2) { i -> Int? in
            i * 10
        }

        #expect(results.count == 5)
        #expect(Set(results) == Set([0, 10, 20, 30, 40]))
    }

    @Test func filtersNilResults() async throws {
        let results = try await batchMap(count: 6, batchSize: 3) { i -> Int? in
            i.isMultiple(of: 2) ? i : nil
        }

        #expect(results.count == 3)
        #expect(Set(results) == Set([0, 2, 4]))
    }

    @Test func processesAllIndices() async throws {
        let tracker = IndexTracker()

        _ = try await batchMap(count: 10, batchSize: 3) { i -> Int? in
            await tracker.visit(i)
            return i
        }

        let visited = await tracker.visited
        #expect(visited == Set(0 ..< 10))
    }

    // MARK: - Edge Cases

    @Test func zeroCount() async throws {
        let results = try await batchMap(count: 0, batchSize: 4) { _ -> Int? in
            Issue.record("Worker should not be called for count 0")
            return nil
        }

        #expect(results.isEmpty)
    }

    @Test func countLessThanBatchSize() async throws {
        let results = try await batchMap(count: 2, batchSize: 8) { i -> Int? in
            i
        }

        #expect(results.count == 2)
        #expect(Set(results) == Set([0, 1]))
    }

    @Test func countEqualsBatchSize() async throws {
        let results = try await batchMap(count: 4, batchSize: 4) { i -> Int? in
            i
        }

        #expect(results.count == 4)
        #expect(Set(results) == Set([0, 1, 2, 3]))
    }

    @Test func singleItem() async throws {
        let results = try await batchMap(count: 1, batchSize: 4) { i -> Int? in
            #expect(i == 0)
            return 42
        }

        #expect(results == [42])
    }

    @Test func batchSizeOne() async throws {
        let results = try await batchMap(count: 5, batchSize: 1) { i -> Int? in
            i
        }

        #expect(results.count == 5)
        #expect(Set(results) == Set(0 ..< 5))
    }

    @Test func allNilResultsReturnsEmpty() async throws {
        let results = try await batchMap(count: 5, batchSize: 3) { _ -> String? in
            nil
        }

        #expect(results.isEmpty)
    }

    // MARK: - Error Propagation

    @Test func workerErrorPropagates() async {
        struct TestError: Error {}

        await #expect(throws: TestError.self) {
            try await batchMap(count: 5, batchSize: 2) { i -> Int? in
                if i == 3 { throw TestError() }
                return i
            }
        }
    }

    // MARK: - Cancellation

    @Test func respectsCancellation() async {
        let task = Task {
            try await batchMap(count: 1000, batchSize: 2) { i -> Int? in
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                return i
            }
        }

        task.cancel()

        let result = await task.result

        switch result {
        case .success:
            Issue.record("Expected cancellation error")
        case let .failure(error):
            #expect(error is CancellationError)
        }
    }

    // MARK: - Concurrency

    @Test func respectsBatchSizeLimit() async throws {
        let counter = ConcurrencyCounter()

        _ = try await batchMap(count: 20, batchSize: 4) { i -> Int? in
            await counter.enter()

            // Small delay to allow overlap
            try await Task.sleep(nanoseconds: 5_000_000) // 5ms

            await counter.exit()

            return i
        }

        let peak = await counter.peak
        #expect(peak <= 4, "Peak concurrency \(peak) exceeded batch size 4")
    }
}

// MARK: - Test Helpers

/// Thread-safe tracker for visited indices.
private actor IndexTracker {
    var visited = Set<Int>()

    func visit(_ index: Int) {
        visited.insert(index)
    }
}

/// Thread-safe counter for tracking peak concurrency.
private actor ConcurrencyCounter {
    private var current = 0
    private(set) var peak = 0

    func enter() {
        current += 1
        peak = max(peak, current)
    }

    func exit() {
        current -= 1
    }
}
