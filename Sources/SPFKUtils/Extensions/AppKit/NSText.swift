// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import AppKit

    extension NSTextAlignment {
        public var alignmentMode: CATextLayerAlignmentMode {
            switch self {
            case .left:
                .left
            case .center:
                .center
            case .right:
                .right
            case .justified:
                .justified
            case .natural:
                .natural
            @unknown default:
                .left
            }
        }
    }

    extension NSTextField {
        public var textSize: NSSize {
            guard let font else {
                return frame.size
            }

            let fontAttributes = [NSAttributedString.Key.font: font]
            let size = stringValue.size(withAttributes: fontAttributes)

            return size
        }
    }

#endif
