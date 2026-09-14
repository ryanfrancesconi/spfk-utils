// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// The outcome of one item in a ``BatchFileConverter`` run.
public enum BatchFileConversionResult<Work: FileConversionWork>: Sendable {
    /// The item as its converter returned it.
    case success(Work)

    /// The item as it was handed to the converter.
    case failed(Work, any Error)

    public var work: Work {
        switch self {
        case let .success(work), let .failed(work, _): work
        }
    }

    public var error: (any Error)? {
        guard case let .failed(_, error) = self else { return nil }
        return error
    }
}
