// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKBase

/// Runs `work` once per item, `kind.width` at a time, with each item's failure isolated.
///
/// A thrown error other than cancellation is logged, passed to `failed` with the item's `name`, and
/// counted toward progress; the batch goes on. Cancellation ends the batch and rethrows. `completed`
/// receives each result with the fraction of items finished, and the results come back in input order.
///
/// Autoreleased objects need no pool here: the concurrency runtime drains one at the end of every job,
/// so an item's objects are gone before the next item on that thread starts.
public func processBatch<R: Sendable>(
    count: Int,
    kind: BatchWorkKind,
    name: @escaping @Sendable (Int) -> String,
    work: @escaping @Sendable (Int) async throws -> R,
    completed: (@Sendable (R, UnitInterval) async throws -> Void)? = nil,
    failed: (@Sendable (String, any Error) async -> Void)? = nil
) async throws -> [R] {
    let progress = ProgressTracker(total: count)

    let results = try await batchMap(count: count, batchSize: kind.width) { position -> (Int, R)? in
        do {
            let result = try await work(position)
            try await completed?(result, await progress.increment())
            return (position, result)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            let name = name(position)
            Log.error(name, error)
            await failed?(name, error)
            _ = await progress.increment()
            return nil
        }
    }

    return results.sorted { $0.0 < $1.0 }.map(\.1)
}
