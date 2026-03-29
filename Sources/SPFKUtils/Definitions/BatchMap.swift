// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// Processes `count` items concurrently with a sliding window of `batchSize`.
///
/// The worker closure receives an index (0..<count) and returns an optional result.
/// Nil results are filtered out. Cancellation is checked between iterations.
///
/// ## Choosing a batchSize
///
/// The right `batchSize` depends on whether the work inside the closure **blocks**
/// a thread or **suspends** a task:
///
/// **Blocking work** (CPU computation, synchronous syscalls, XPC calls that don't
/// yield): each running task occupies a cooperative thread for its full duration.
/// Swift's thread pool has a fixed size equal to the active CPU core count, so
/// running more tasks than cores provides no throughput benefit — extra tasks just
/// queue up waiting for a thread. Set `batchSize` to roughly the core count
/// (`ProcessInfo.processInfo.activeProcessorCount`).
///
/// **Suspending work** (async network requests, async file I/O — anything that
/// genuinely hits `await` and releases its thread while waiting): tasks do not hold
/// a thread while suspended, so the thread pool is not the bottleneck. Hundreds of
/// tasks can be in flight simultaneously with only 8 threads. In this case `batchSize`
/// is a resource-management knob — use it to cap memory overhead, rate-limit an
/// external service, or limit open file handles, not to protect the thread pool.
/// A much higher value (or removing the cap entirely) is appropriate here.
public func batchMap<R: Sendable>(
    count: Int,
    batchSize: Int,
    worker: @Sendable @escaping (Int) async throws -> R?
) async throws -> [R] {
    guard count > 0 else { return [] }

    return try await withThrowingTaskGroup(
        of: R?.self,
        returning: [R].self
    ) { taskGroup in
        try Task.checkCancellation()

        for i in 0 ..< min(batchSize, count) {
            taskGroup.addTask { try await worker(i) }
        }

        var index = batchSize
        var results = [R]()

        for try await result in taskGroup {
            try Task.checkCancellation()

            if let result {
                results.append(result)
            }

            if index < count {
                taskGroup.addTask { [index] in
                    try await worker(index)
                }
                index += 1
            }
        }

        return results
    }
}
