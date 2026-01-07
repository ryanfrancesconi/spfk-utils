import CoreGraphics
import Foundation

extension CGColor {
    public static func from(hexColor: HexColor) -> CGColor? {
        from(hexString: hexColor.hexString)
    }

    public static func from(hexString: String) -> CGColor? {
        let hexColor = hexString.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0

        guard scanner.scanHexInt64(&hexNumber) else { return nil }

        let red = CGFloat((hexNumber & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hexNumber & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat((hexNumber & 0x0000FF) >> 0) / 255.0

        return self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }

    public func toHex(alpha: Bool = false) -> String? {
        guard let components,
              components.count >= 3
        else {
            return nil
        }

        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        if alpha {
            return String(
                format: "%02lX%02lX%02lX%02lX",
                lroundf(r * 255),
                lroundf(g * 255),
                lroundf(b * 255),
                lroundf(a * 255)
            )
        } else {
            return String(
                format: "%02lX%02lX%02lX",
                lroundf(r * 255),
                lroundf(g * 255),
                lroundf(b * 255)
            )
        }
    }
}
