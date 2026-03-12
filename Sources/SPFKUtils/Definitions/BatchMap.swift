// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// Processes `count` items concurrently with a sliding window of `batchSize`.
///
/// The worker closure receives an index (0..<count) and returns an optional result.
/// Nil results are filtered out. Cancellation is checked between iterations.
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
