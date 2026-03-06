// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

extension Entropy {
    nonisolated(unsafe) private static let uniqueIdEntropy = Entropy(.charset32)
    private static let uniqueIdEntropyBits = Entropy.bits(for: 10000, risk: 1.0e6)

    /// Convenience for returning an entropy based unique ID
    public static var uniqueId: String {
        uniqueIdEntropy.string(bits: uniqueIdEntropyBits)
    }
}
