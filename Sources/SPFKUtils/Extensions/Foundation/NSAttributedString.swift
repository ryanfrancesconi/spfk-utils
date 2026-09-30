// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

extension NSAttributedString {
    public static func link(
        _ link: String? = nil,
        to url: URL,
        attributes attrs: [NSAttributedString.Key: Any]? = nil
    ) -> NSMutableAttributedString {
        
        let link = link ?? url.absoluteString
        
        let str = NSMutableAttributedString(string: link, attributes: attrs)
        str.addAttribute(.link, value: url, range: NSRange(link.startIndex..., in: link))
        return str
    }

    public static var newline: NSAttributedString {
        .init(string: "\n")
    }
}

extension NSAttributedString {
    public func height(withConstrainedWidth width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = boundingRect(
            with: constraintRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading], // Required for multi-line and font-specific calc
            context: nil
        )

        return ceil(boundingBox.height)
    }
}
