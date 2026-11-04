// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// What a batch item spends its time on, which sets how many run at once.
///
/// A tool picks the kind rather than a number. A tool that needs a different width says why in
/// ``custom(_:)``, with the measurement behind it.
public enum BatchWorkKind: Sendable, Equatable {
    /// Decode, analysis or rendering that holds a cooperative thread for the whole item.
    ///
    /// Kept below the core count: with every core decoding, a task posted to the pool ran up to
    /// seconds late, which an app shows as a stall. Two cores fewer cost about a tenth of the speed.
    case blocking

    /// Metadata reads and writes, and work done in memory.
    case fileIO

    /// One item at a time.
    case serial

    case custom(Int)

    public var width: Int {
        switch self {
        case .blocking: Self.blockingWidth
        case .fileIO: 8
        case .serial: 1
        case let .custom(width): max(1, width)
        }
    }

    /// Two cores fewer than the machine has, between 2 and 8.
    static let blockingWidth = min(8, max(2, ProcessInfo.processInfo.activeProcessorCount - 2))
}
