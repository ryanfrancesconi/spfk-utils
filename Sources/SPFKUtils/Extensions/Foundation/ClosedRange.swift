// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

extension ClosedRange<TimeInterval> {
    public var duration: TimeInterval {
        upperBound - lowerBound
    }
}
