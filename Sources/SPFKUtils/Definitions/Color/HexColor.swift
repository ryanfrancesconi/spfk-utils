// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
    import CoreGraphics
    import Foundation

    public struct HexColor: Hashable, Sendable, Equatable {
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.stringValue == rhs.stringValue
        }

        public private(set) var stringValue: String = "FFFFFFFF"

        public private(set) var red: CGFloat = 1
        public private(set) var green: CGFloat = 1
        public private(set) var blue: CGFloat = 1
        public private(set) var alpha: CGFloat = 1

        public var nsColor: NSColor? {
            NSColor.from(hexColor: self)
        }

        public var cgColor: CGColor? {
            CGColor(red: red, green: green, blue: blue, alpha: alpha)
        }

        public init?(nsColor: NSColor) {
            guard let string = nsColor.toHex() else {
                return nil
            }

            stringValue = string
            parse()
        }

        public init(string: String) {
            stringValue = string
            parse()
        }

        private mutating func parse() {
            let string = stringValue.replacingOccurrences(of: "#", with: "")

            let scanner = Scanner(string: string)

            var hexNumber: UInt64 = 0
            guard scanner.scanHexInt64(&hexNumber) else { return }

            // alpha channel, FF000080
            if string.count == 8 {
                red = CGFloat((hexNumber & 0xFF00_0000) >> 24) / 255.0
                green = CGFloat((hexNumber & 0x00FF_0000) >> 16) / 255.0
                blue = CGFloat((hexNumber & 0x0000_FF00) >> 8) / 255.0
                alpha = CGFloat(hexNumber & 0x0000_00FF) / 255.0

                alpha = alpha.rounded(decimalPlaces: 2)

                // FF0000
            } else if string.count == 6 {
                red = CGFloat((hexNumber & 0xFF0000) >> 16) / 255.0
                green = CGFloat((hexNumber & 0x00FF00) >> 8) / 255.0
                blue = CGFloat((hexNumber & 0x0000FF) >> 0) / 255.0

            } else {
                assertionFailure("invalid string \(string)")
            }
        }
    }

    extension HexColor: Codable {
        enum CodingKeys: String, CodingKey {
            case stringValue
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            if let value = try? container.decodeIfPresent(String.self, forKey: .stringValue) {
                stringValue = value
                parse()
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(stringValue, forKey: .stringValue)
        }
    }

#endif // canImport(AppKit)
