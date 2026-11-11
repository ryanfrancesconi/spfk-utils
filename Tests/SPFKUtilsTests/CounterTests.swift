// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKUtils
import Testing

final class CounterTests {
    @Test func resetFromCustomValue() {
        var counter = Counter(startingValue: 50)
        _ = counter.next()
        counter.reset()
        // reset always goes to 0
        #expect(counter.next() == 1)
    }
}
