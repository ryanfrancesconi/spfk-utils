import AudioToolbox
import SPFKUtils
import Testing

final class NumberTests {
    @Test func normalized() {
        let value: AUValue = 1

        #expect(
            value.normalized(from: 0 ... 2, taper: AUValue(3)) == 0.7937005
        )
    }

    @Test func roundToNearestPowerOfTwo() {
        #expect(0.roundToNearestPowerOfTwo() == 1)
        #expect(2.roundToNearestPowerOfTwo() == 2)
        #expect(3.roundToNearestPowerOfTwo() == 4)
        #expect(11.roundToNearestPowerOfTwo() == 8)
        #expect(134.roundToNearestPowerOfTwo() == 128)
        #expect(150.roundToNearestPowerOfTwo() == 128)
        #expect(240.roundToNearestPowerOfTwo() == 256)
        #expect(444.roundToNearestPowerOfTwo() == 512)
        #expect(1111.roundToNearestPowerOfTwo() == 1024)
        #expect(-100.roundToNearestPowerOfTwo() == -128)
    }
}
