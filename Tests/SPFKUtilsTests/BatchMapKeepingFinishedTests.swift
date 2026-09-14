// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import SPFKUtils
import Testing

struct BatchMapKeepingFinishedTests {
    @Test func everyResultIsReturnedWhenNothingIsCancelled() async {
        let results = await batchMapKeepingFinished(count: 10, batchSize: 3) { index -> Int? in index * 2 }

        #expect(results.sorted() == (0 ..< 10).map { $0 * 2 })
    }

    @Test func nilResultsAreDropped() async {
        let results = await batchMapKeepingFinished(count: 6, batchSize: 2) { index -> Int? in
            index.isMultiple(of: 2) ? index : nil
        }

        #expect(results.sorted() == [0, 2, 4])
    }

    /// Cancelled while the first item runs: its result is kept, and nothing after it starts.
    @Test func aCancelKeepsWhatStartedAndStartsNothingMore() async {
        let (started, startedContinuation) = AsyncStream<Void>.makeStream()

        let task = Task {
            await batchMapKeepingFinished(count: 5, batchSize: 1) { index -> Int? in
                if index == 0 {
                    startedContinuation.yield()
                    // Ends early when the cancel arrives.
                    try? await Task.sleep(nanoseconds: 10_000_000_000)
                }

                return index
            }
        }

        for await _ in started {
            break
        }

        task.cancel()

        #expect(await task.value == [0])
    }

    /// Cancelled with a full batch running: every item already started is kept, and nothing more starts.
    @Test func aCancelKeepsEveryItemAlreadyRunning() async {
        let (started, startedContinuation) = AsyncStream<Void>.makeStream()
        let gauge = ConcurrencyGauge()

        let task = Task {
            await batchMapKeepingFinished(count: 10, batchSize: 3) { index -> Int? in
                await gauge.enter()
                startedContinuation.yield()
                // Ends early when the cancel arrives.
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                return index
            }
        }

        var startCount = 0
        for await _ in started {
            startCount += 1
            if startCount == 3 { break }
        }

        task.cancel()

        #expect(await task.value.sorted() == [0, 1, 2])
        #expect(await gauge.entries == 3)
    }

    @Test func fewerItemsThanTheBatchSizeRunsEachOnce() async {
        let results = await batchMapKeepingFinished(count: 2, batchSize: 6) { index -> Int? in index }

        #expect(results.sorted() == [0, 1])
    }

    @Test func neverRunsMoreThanTheBatchSizeAtOnce() async {
        let gauge = ConcurrencyGauge()

        let results = await batchMapKeepingFinished(count: 20, batchSize: 4) { index -> Int? in
            await gauge.enter()
            try? await Task.sleep(nanoseconds: 5_000_000)
            await gauge.leave()
            return index
        }

        #expect(results.count == 20)
        #expect(await gauge.peak <= 4)
    }
}

private actor ConcurrencyGauge {
    private(set) var entries = 0
    private(set) var peak = 0
    private var running = 0

    func enter() {
        entries += 1
        running += 1
        peak = max(peak, running)
    }

    func leave() {
        running -= 1
    }
}
