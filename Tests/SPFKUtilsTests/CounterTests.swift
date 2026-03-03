// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKUtils
import Testing

final class CounterTests {
    @Test func defaultInitialValue() {
        var counter = Counter()
        #expect(counter.next() == 1)
    }

    @Test func customStartingValue() {
        var counter = Counter(startingValue: 10)
        #expect(counter.next() == 11)
    }

    @Test func multipleIncrements() {
        var counter = Counter()
        #expect(counter.next() == 1)
        #expect(counter.next() == 2)
        #expect(counter.next() == 3)
    }

    @Test func reset() {
        var counter = Counter()
        _ = counter.next()
        _ = counter.next()
        counter.reset()
        #expect(counter.next() == 1)
    }

    @Test func resetFromCustomValue() {
        var counter = Counter(startingValue: 50)
        _ = counter.next()
        counter.reset()
        // reset always goes to 0
        #expect(counter.next() == 1)
    }
}
