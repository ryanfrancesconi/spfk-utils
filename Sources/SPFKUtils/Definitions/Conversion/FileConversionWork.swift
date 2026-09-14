// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKFileSystem

/// One file's conversion, as ``BatchFileConverter`` sees it: where it reads, where it writes, and
/// what happens when the output already exists.
public protocol FileConversionWork: Sendable {
    var input: URL { get set }
    var output: URL { get set }

    /// The file ``input`` stands in for, when it is a render of that file with pending edits applied.
    /// A converter refuses an output replacing this file as well as ``input``.
    var originalInput: URL? { get set }

    var conflictScheme: FileConflictScheme { get set }
}

extension FileConversionWork {
    /// The user's own file, never a temp render: the name a result is reported under.
    public var reportedInput: URL { originalInput ?? input }
}
