// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SwiftExtensions

// swiftformat:disable consecutiveSpaces

/// Binary byte size constants for file size and disk space calculations.
///
/// **Available on all Apple platforms** (macOS, iOS, tvOS, watchOS).
///
/// Raw values represent the exact number of bytes for each unit (powers of 1024).
/// Use ``toString(_:)`` and ``fromString(_:)`` for human-readable file size formatting.
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

    /// Parse a human-readable byte count string back to a numeric value.
    /// - Parameter string: A string such as "1 MB" or "160.2 MB".
    /// - Returns: The byte count, or `nil` if parsing failed.
    public static func fromString(_ string: String) -> UInt64? {
        let parts = string.components(separatedBy: " ")

        guard let number = parts.first?.double,
              let text = parts.last?.uppercased() else { return nil }

        switch text {
        case "KB":
            return (number * ByteCount.kilobyte.rawValue.double).uInt64
        case "MB":
            return (number * ByteCount.megabyte.rawValue.double).uInt64
        case "GB":
            return (number * ByteCount.gigabyte.rawValue.double).uInt64
        case "TB":
            return (number * ByteCount.terabyte.rawValue.double).uInt64
        default:
            return nil
        }
    }
}

// swiftformat:enable consecutiveSpaces
