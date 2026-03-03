// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
@testable import SPFKUtils
import Testing

final class EntropyTests {
    @Test func smallIDNotEmpty() {
        let entropy = Entropy()
        let id = entropy.smallID()
        #expect(!id.isEmpty)
    }

    @Test func mediumIDNotEmpty() {
        let entropy = Entropy()
        let id = entropy.mediumID()
        #expect(!id.isEmpty)
    }

    @Test func largeIDNotEmpty() {
        let entropy = Entropy()
        let id = entropy.largeID()
        #expect(!id.isEmpty)
    }

    @Test func sessionIDLength() {
        let entropy = Entropy()
        let id = entropy.sessionID()
        // 128 bits / 5 bits per char (charset32) = ceil(25.6) = 26 chars
        #expect(id.count == 26)
    }

    @Test func tokenLength() {
        let entropy = Entropy()
        let id = entropy.token()
        // 256 bits / 5 bits per char (charset32) = ceil(51.2) = 52 chars
        #expect(id.count == 52)
    }

    @Test func uniqueIDs() {
        let entropy = Entropy()
        let ids = (0 ..< 100).map { _ in entropy.mediumID() }
        let unique = Set(ids)
        #expect(unique.count == 100)
    }

    @Test func customCharset() throws {
        let entropy = try Entropy("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")
        let id = entropy.mediumID()
        #expect(!id.isEmpty)
    }

    @Test func zeroBitsReturnsEmpty() {
        let entropy = Entropy()
        let id = entropy.string(bits: 0)
        #expect(id.isEmpty)
    }

    @Test func charset64() {
        let entropy = Entropy(.charset64)
        let id = entropy.smallID()
        #expect(!id.isEmpty)
    }

    @Test func charset16() {
        let entropy = Entropy(.charset16)
        let id = entropy.smallID()
        // hex chars only
        let hexChars = CharacterSet(charactersIn: "0123456789abcdef")
        let allHex = id.unicodeScalars.allSatisfy { hexChars.contains($0) }
        #expect(allHex)
    }

    @Test func bitsCalculation() {
        let bits = Entropy.bits(for: 10000, risk: 1_000_000)
        #expect(bits > 0)
    }

    @Test func bitsForZeroStrings() {
        let bits = Entropy.bits(for: 0, risk: 1_000_000)
        #expect(bits == 0)
    }

    @Test func invalidCharCountThrows() {
        #expect(throws: EntropyStringError.self) {
            _ = try Entropy("ABC") // not a power of 2
        }
    }

    @Test func duplicateCharsThrows() {
        #expect(throws: EntropyStringError.self) {
            _ = try Entropy("AABB") // duplicate characters
        }
    }

    @Test func tooFewBytesThrows() {
        let entropy = Entropy()
        #expect(throws: EntropyStringError.self) {
            _ = try entropy.string(bits: 128, using: [0x00]) // 1 byte not enough for 128 bits
        }
    }

    @Test func negativeBitsThrows() {
        let entropy = Entropy()
        #expect(throws: EntropyStringError.self) {
            _ = try entropy.string(bits: -1, using: [0x00])
        }
    }

    @Test func staticUniqueId() {
        let id1 = Entropy.uniqueId
        let id2 = Entropy.uniqueId
        #expect(id1 != id2)
        #expect(!id1.isEmpty)
    }

    @Test func useCharset() {
        let entropy = Entropy()
        entropy.use(.charset64)
        #expect(entropy.charset.chars.count == 64)
    }

    @Test func useStringCharset() throws {
        let entropy = Entropy()
        try entropy.use("0123456789abcdef")
        #expect(entropy.charset.chars.count == 16)
    }
}
