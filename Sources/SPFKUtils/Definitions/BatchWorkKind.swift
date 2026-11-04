// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// What a batch item spends its time on, which sets how many run at once.
///
/// A tool picks the kind rather than a number. A tool that needs a different width says why in
/// ``custom(_:)``, with the measurement behind it.
public enum BatchWorkKind: Sendable, Equatable {
    /// Decode, analysis or rendering that holds a cooperative thread for the whole item.
    ///
    /// Two fewer than the cores, since the cooperative pool has one thread per core: on 10 cores,
    /// ten at a time made a task posted to the pool run up to seconds late, which an app shows as a
    /// stall; eight did not, for about a tenth of the speed.
    case blocking

    /// Rendering an edit to a new file, which holds the whole decoded signal per item.
    ///
    /// Four, or one per 4 GB of memory where that is fewer, and never below 2. On 32 GB, a fade on
    /// files over 20 MB peaked at 2.5 GB six at a time and 1.8 GB four at a time in the same time,
    /// so more cores do not make more renders worth their memory; two at a time was half again slower.
    case render

    /// Metadata reads and writes, and work done in memory.
    case fileIO

    /// One item at a time.
    case serial

    case custom(Int)

    public var width: Int {
        switch self {
        case .blocking: Self.blockingWidth
        case .render: Self.renderWidth
        case .fileIO: 8
        case .serial: 1
        case let .custom(width): max(1, width)
        }
    }

    static let blockingWidth = blockingWidth(activeCores: ProcessInfo.processInfo.activeProcessorCount)

    static let renderWidth = renderWidth(memory: ProcessInfo.processInfo.physicalMemory, blockingWidth: blockingWidth)

    static func blockingWidth(activeCores: Int) -> Int {
        max(2, activeCores - 2)
    }

    static func renderWidth(memory: UInt64, blockingWidth: Int) -> Int {
        let perFourGB = Int(memory / (4 << 30))
        return min(4, blockingWidth, max(2, perFourGB))
    }
}
