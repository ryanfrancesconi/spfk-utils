import Foundation

extension FixedWidthInteger {
    public func roundToNearestPowerOfTwo() -> Self {
        // Handle non-positive values, 1 is the smallest positive power of 2
        guard self > 0 else { return 1 }

        // Find the power of 2 immediately below or equal to the value
        let lowerValue: Self = 1 << (.bitWidth - leadingZeroBitCount - 1)

        // Find the power of 2 immediately above the value
        let upperValue: Self = lowerValue * 2

        // Determine which power of 2 is closer
        if self - lowerValue < upperValue - self {
            return lowerValue
        } else {
            return upperValue
        }
    }
}

extension Int {
    public func incremented(by value: Int = 1) -> Int {
        self + value
    }

    public func decremented(by value: Int = 1) -> Int {
        self - value
    }
}
