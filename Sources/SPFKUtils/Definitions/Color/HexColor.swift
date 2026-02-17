
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
    import CoreGraphics

    public struct HexColor: Hashable, Sendable {
        public static let random = HexColor(nsColor: .random)

        public var hexString: String

        public var nsColor: NSColor? {
            NSColor.from(hexColor: self)
        }

        public var cgColor: CGColor? {
            CGColor.from(hexColor: self)
        }

        public init?(nsColor: NSColor) {
            guard let string = nsColor.toHex() else {
                return nil
            }

            hexString = string
        }

        public init(hexString: String) {
            self.hexString = hexString
        }
    }

    extension HexColor: Codable {
        enum CodingKeys: String, CodingKey {
            case hexString
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            let value = try container.decode(String.self, forKey: .hexString)

            hexString = value
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(hexString, forKey: .hexString)
        }
    }

    extension NSColor {
        public var hexColor: HexColor? {
            guard let hexString = toHex() else { return nil }
            return HexColor(hexString: hexString)
        }
    }
#endif // canImport(AppKit)
