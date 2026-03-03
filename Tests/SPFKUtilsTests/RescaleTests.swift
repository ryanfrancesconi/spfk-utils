// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKUtils
import Testing

final class RescaleTests {
    @Test func interpolateZero() {
        let r = Rescale(domain0: 0, domain1: 10, range0: 0, range1: 100)
        #expect(r.interpolate(0) == 0)
    }

    @Test func interpolateOne() {
        let r = Rescale(domain0: 0, domain1: 10, range0: 0, range1: 100)
        #expect(r.interpolate(1) == 100)
    }

    @Test func interpolateHalf() {
        let r = Rescale(domain0: 0, domain1: 10, range0: 0, range1: 100)
        #expect(r.interpolate(0.5) == 50)
    }

    @Test func uninterpolate() {
        let r = Rescale(domain0: 0, domain1: 10, range0: 0, range1: 100)
        #expect(r.uninterpolate(5) == 0.5)
    }

    @Test func uninterpolateZeroDomain() {
        // domain0 == domain1 == 0, fallback to b = 1
        let r = Rescale(domain0: 0, domain1: 0, range0: 0, range1: 100)
        let result = r.uninterpolate(5)
        #expect(result.isFinite)
        #expect(result == 5)
    }

    @Test func rescaleIdentity() {
        let r = Rescale(domain0: 0, domain1: 100, range0: 0, range1: 100)
        #expect(r.rescale(50) == 50)
    }

    @Test func rescaleDomainToRange() {
        let r = Rescale(domain0: 0, domain1: 10, range0: 0, range1: 100)
        #expect(r.rescale(5) == 50)
    }

    @Test func rescaleInvertedRange() {
        let r = Rescale(domain0: 0, domain1: 10, range0: 100, range1: 0)
        #expect(r.rescale(0) == 100)
        #expect(r.rescale(10) == 0)
    }

    @Test func rescaleBoundaries() {
        let r = Rescale(domain0: 0, domain1: 10, range0: 0, range1: 100)
        #expect(r.rescale(0) == 0)
        #expect(r.rescale(10) == 100)
    }

    @Test func rescaleNegativeDomain() {
        let r = Rescale(domain0: -10, domain1: 10, range0: 0, range1: 100)
        #expect(r.rescale(0) == 50)
    }
}
