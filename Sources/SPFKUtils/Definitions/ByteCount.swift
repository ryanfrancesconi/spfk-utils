// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SwiftExtensions

// swiftformat:disable consecutiveSpaces

/// Binary byte size constants for file size and disk space calculations.
///
/// **Available on all Apple platforms** (macOS, iOS, tvOS, watchOS).
///
/// Raw values represent the exact number of bytes for each unit (powers of 1024).
/// Use ``toString(_:)`` for human-readable file size formatting.
public enum ByteCount: UInt64 {
    case byte     = 1
    case kilobyte = 1024
    case megabyte = 1_048_576
    case gigabyte = 1_073_741_824
    case terabyte = 1_099_511_627_776
    case petabyte = 1_125_899_906_842_624
    case exabyte  = 1_152_921_504_606_846_976

    // MARK: - Formatting

    /// Convert bytes to a human-readable string.
    /// - Parameter byteCount: The byte count to format.
    /// - Returns: A readable string such as "1 MB".
    public static func toString(_ byteCount: Int64) -> String? {
        ByteCountFormatter.string(fromByteCount: byteCount, countStyle: .file)
    }
}

// swiftformat:enable consecutiveSpaces
