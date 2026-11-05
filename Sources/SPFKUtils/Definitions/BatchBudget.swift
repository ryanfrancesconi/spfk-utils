// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// How many batch items run at once across the whole process, whichever batch they belong to.
///
/// Each batch sizes itself as if it had the machine alone, so two at once can occupy every
/// cooperative thread between them: Normalize alongside a save rendering fades made a task posted
/// to the pool run up to 3 s late on 10 cores, where either alone stayed under 5 ms. A batch with
/// nothing running may exceed ``capacity`` by one item, so a batch whose item waits on another
/// batch, as a detached task inside an item can, still progresses.
public final class BatchBudget: @unchecked Sendable {
    public static let shared = BatchBudget(BatchWorkKind.blocking.width)

    /// One batch's count of running items. Create one per batch and pass it to every item.
    final class Lease: @unchecked Sendable {
        fileprivate var running = 0
    }

    private struct Waiter {
        let lease: Lease
        let continuation: CheckedContinuation<Void, Never>
    }

    /// Items inside a batch item take no slots: the item they run in already holds one.
    @TaskLocal static var isHoldingSlot = false

    private let lock = NSLock()
    private var inUse = 0
    private var waiting: [Waiter] = []

    public let capacity: Int

    public init(_ capacity: Int) {
        self.capacity = max(1, capacity)
    }

    /// Runs `body` holding a slot, waiting for one first if every slot is taken.
    func withSlot<T: Sendable>(_ lease: Lease, _ body: () async throws -> T) async rethrows -> T {
        guard !Self.isHoldingSlot else { return try await body() }

        await acquire(lease)
        defer { release(lease) }
        return try await Self.$isHoldingSlot.withValue(true) { try await body() }
    }

    private func canTake(_ lease: Lease) -> Bool {
        inUse < capacity || lease.running == 0
    }

    private func take(_ lease: Lease) {
        inUse += 1
        lease.running += 1
    }

    private func acquire(_ lease: Lease) async {
        let taken = lock.withLock {
            guard canTake(lease) else { return false }
            take(lease)
            return true
        }
        guard !taken else { return }

        await withCheckedContinuation { continuation in
            // A slot may have come back between the check above and here.
            let takenNow = lock.withLock {
                guard canTake(lease) else {
                    waiting.append(Waiter(lease: lease, continuation: continuation))
                    return false
                }
                take(lease)
                return true
            }
            if takenNow { continuation.resume() }
        }
    }

    private func release(_ lease: Lease) {
        let resumed = lock.withLock { () -> [CheckedContinuation<Void, Never>] in
            inUse -= 1
            lease.running -= 1

            var resumed = [CheckedContinuation<Void, Never>]()
            var index = 0
            while index < waiting.count {
                let waiter = waiting[index]
                if canTake(waiter.lease) {
                    take(waiter.lease)
                    resumed.append(waiting.remove(at: index).continuation)
                } else {
                    index += 1
                }
            }
            return resumed
        }

        for continuation in resumed { continuation.resume() }
    }
}
