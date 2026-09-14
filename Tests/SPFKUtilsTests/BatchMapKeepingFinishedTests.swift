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
}
