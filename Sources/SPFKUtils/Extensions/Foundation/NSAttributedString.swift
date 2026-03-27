// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

extension NSAttributedString {
    public convenience init?(htmlString: String) {
        guard let data = htmlString.data(using: .unicode) else {
            return nil
        }

        try? self.init(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil
        )
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
