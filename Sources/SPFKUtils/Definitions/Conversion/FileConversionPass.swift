// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// Items of one ``BatchFileConverter`` run converted `batchSize` at a time, for work whose cost differs
/// enough by kind to want its own concurrency. Passes run in order, each after the last has finished.
public struct FileConversionPass: Sendable, Equatable {
    /// Indexes into the converter's work. One named by an earlier pass is not run again.
    public var indexes: [Int]

    public var batchSize: Int

    public init(indexes: [Int], batchSize: Int = Self.defaultBatchSize) {
        self.indexes = indexes
        self.batchSize = max(1, batchSize)
    }

    public static let defaultBatchSize = 8
}
