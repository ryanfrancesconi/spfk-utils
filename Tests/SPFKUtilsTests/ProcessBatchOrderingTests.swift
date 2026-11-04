// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import SPFKBase
import SPFKUtils
import Testing

struct ProcessBatchOrderingTests {
    private struct Failure: Error {}

    private actor Recorder<T: Sendable> {
        var entries: [T] = []
        func append(_ entry: T) { entries.append(entry) }
    }

    /// At every core busy, a task posted to the pool ran seconds late; blocking work leaves cores free.
    @Test func blockingWorkLeavesCoresFree() {
        let cores = ProcessInfo.processInfo.activeProcessorCount
        #expect(BatchWorkKind.blocking.width < cores || cores <= 2)
        #expect(BatchWorkKind.blocking.width >= 1)
    }

    @Test func resultsComeBackInInputOrder() async throws {
        // Later items finish first.
        let results = try await processBatch(count: 6, kind: .blocking, name: { "\($0)" }) { index -> String in
            try await Task.sleep(nanoseconds: UInt64(6 - index) * 5_000_000)
            return "photo-\(index).heic"
        }

        #expect(results == (0 ..< 6).map { "photo-\($0).heic" })
    }

    @Test func aFailingItemIsReportedByNameAndTheRestRun() async throws {
        let failures = Recorder<String>()

        let results = try await processBatch(
            count: 5, kind: .blocking, name: { "file-\($0)" },
            work: { index -> Int in
                if index == 2 { throw Failure() }
                return index
            },
            failed: { name, _ in await failures.append(name) }
        )

        #expect(results == [0, 1, 3, 4])
        #expect(await failures.entries == ["file-2"])
    }

    @Test func progressCountsFailuresAndReachesOne() async throws {
        let progress = Recorder<UnitInterval>()

        _ = try await processBatch(
            count: 4, kind: .blocking, name: { "\($0)" },
            work: { index -> Int in
                if index == 1 { throw Failure() }
                return index
            },
            completed: { _, value in await progress.append(value) }
        )

        let values = await progress.entries
        #expect(values.count == 3)
        #expect(values.sorted() == values)
        // The failure counted toward progress, so the last success may be at 1 or 0.75.
        #expect((values.last ?? 0) >= 0.75)
    }

    @Test func aThrowingCompletionCountsAsThatItemsFailure() async throws {
        let failures = Recorder<String>()

        let results = try await processBatch(
            count: 3, kind: .blocking, name: { "\($0)" },
            work: { $0 },
            completed: { result, _ in if result == 1 { throw Failure() } },
            failed: { name, _ in await failures.append(name) }
        )

        #expect(results == [0, 2])
        #expect(await failures.entries == ["1"])
    }

    @Test func cancellingStopsNewItemsAndRethrows() async {
        let started = Recorder<Int>()
        let (firstStarted, signal) = AsyncStream<Void>.makeStream()

        let task = Task {
            try await processBatch(count: 50, kind: .blocking, name: { "\($0)" }) { index -> Int in
                await started.append(index)
                if index == 0 { signal.yield() }
                try await Task.sleep(nanoseconds: 50_000_000)
                return index
            }
        }

        for await _ in firstStarted { break }
        task.cancel()

        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(await started.entries.count <= BatchWorkKind.blocking.width)
    }

    @Test func anItemsAutoreleasedObjectsAreFreedBeforeTheNextItemStarts() async throws {
        let freedBeforeStart = Recorder<Int>()

        _ = try await processBatch(count: 5, kind: .serial, name: { "\($0)" }) { _ -> Int in
            await freedBeforeStart.append(AutoreleaseMarker.freed.value)
            AutoreleaseMarker.autoreleaseOne()
            return 0
        }

        #expect(await freedBeforeStart.entries == [0, 1, 2, 3, 4])
    }
}

private final class AutoreleaseMarker: NSObject {
    final class Counter: @unchecked Sendable {
        private let lock = NSLock()
        private var count = 0
        var value: Int { lock.withLock { count } }
        func increment() { lock.withLock { count += 1 } }
    }

    static let freed = Counter()

    static func autoreleaseOne() {
        _ = Unmanaged.passRetained(AutoreleaseMarker()).autorelease()
    }

    deinit { Self.freed.increment() }
}
