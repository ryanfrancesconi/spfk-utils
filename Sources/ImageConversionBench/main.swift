// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

// Image conversion through `BatchFileConverter` and `ImageFormatConverter`, as Convert Files runs
// it, against a frozen folder of real photos at `IMAGE_CONVERSION_CORPUS`.
//
// An executable, not a test suite: the numbers only mean anything compiled `-O`, and it asserts
// nothing.
//
// Run:
//   scripts/xcb.sh -scheme spfk-image-conversion-bench -configuration Release build
//   P=<derived data>/Build/Products/Release
//   IMAGE_CONVERSION_CORPUS=<copy of the corpus> $P/spfk-image-conversion-bench regress
//
// Outputs go to a temporary folder, removed afterwards; the corpus is only read.

let selectors = CommandLine.arguments.dropFirst().map { $0.lowercased() }

if selectors.contains("regress") {
    try await RegressionSuite.run().write()
} else {
    print("usage: spfk-image-conversion-bench regress [--json <path>]")
}
