import Foundation

/// Scale the domain to the range. The advantage is that you can flip signs to your target range
public struct Rescale {
    public var range0: Double
    public var range1: Double
    public var domain0: Double
    public var domain1: Double

    public init(
        domain0: Double,
        domain1: Double,
        range0: Double,
        range1: Double
    ) {
        self.range0 = range0
        self.range1 = range1
        self.domain0 = domain0
        self.domain1 = domain1
    }

    public func interpolate(_ value: Double) -> Double {
        range0 * (1 - value) + range1 * value
    }

    public func uninterpolate(_ value: Double) -> Double {
        let b: Double = (domain1 - domain0) != 0 ? domain1 - domain0 : 1
        return (value - domain0) / b
    }

    public func rescale(_ value: Double) -> Double {
        interpolate(uninterpolate(value))
    }
}
