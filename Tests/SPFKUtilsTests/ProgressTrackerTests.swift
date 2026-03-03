// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKUtils
import Testing

final class ProgressTrackerTests {
    @Test func initialState() async {
        let tracker = ProgressTracker(total: 10)
        let index = await tracker.index
        let progress = await tracker.progress
        #expect(index == 0)
        #expect(progress == 0)
    }

    @Test func singleIncrement() async {
        let tracker = ProgressTracker(total: 10)
        let progress = await tracker.increment()
        #expect(progress == 0.1)
    }

    @Test func fullCompletion() async {
        let tracker = ProgressTracker(total: 5)
        var lastProgress: Double = 0

        for _ in 0 ..< 5 {
            lastProgress = await tracker.increment()
        }

        #expect(lastProgress == 1.0)
        let index = await tracker.index
        #expect(index == 5)
    }

    @Test func incrementBeyondTotal() async {
        let tracker = ProgressTracker(total: 2)
        _ = await tracker.increment()
        _ = await tracker.increment()
        let progress = await tracker.increment() // beyond total
        #expect(progress == 1.0)
    }

    @Test func zeroTotal() async {
        let tracker = ProgressTracker(total: 0)
        let progress = await tracker.increment()
        #expect(progress == 0)
    }

    @Test func description() async {
        let tracker = ProgressTracker(total: 10)
        _ = await tracker.increment()
        let desc = await tracker.description
        #expect(desc == "1/10")
    }
}

final class ChunkedProgressTrackerTests {
    @Test func initialState() async {
        let tracker = ChunkedProgressTracker(chunklength: 3)
        let total = await tracker.totalCompleted
        #expect(total == 0)
    }

    @Test func singleChunkUpdate() async {
        let tracker = ChunkedProgressTracker(chunklength: 2)
        let total = await tracker.update(index: 0, progress: 1.0)
        // chunk 0 = 1.0, chunk 1 = 0.0, average = 0.5
        #expect(total == 0.5)
    }

    @Test func allChunksComplete() async {
        let tracker = ChunkedProgressTracker(chunklength: 3)
        _ = await tracker.update(index: 0, progress: 1.0)
        _ = await tracker.update(index: 1, progress: 1.0)
        let total = await tracker.update(index: 2, progress: 1.0)
        #expect(total == 1.0)
    }

    @Test func partialProgress() async {
        let tracker = ChunkedProgressTracker(chunklength: 2)
        _ = await tracker.update(index: 0, progress: 0.5)
        let total = await tracker.update(index: 1, progress: 0.5)
        #expect(total == 0.5)
    }

    @Test func progressArray() async {
        let tracker = ChunkedProgressTracker(chunklength: 3)
        _ = await tracker.update(index: 1, progress: 0.75)
        let completed = await tracker.progressCompleted
        #expect(completed[0] == 0)
        #expect(completed[1] == 0.75)
        #expect(completed[2] == 0)
    }
}
