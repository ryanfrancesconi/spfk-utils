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
            font?.size(for: stringValue) ?? frame.size
        }

        /// The height this field needs to show all of its value wrapped at `width`. Asks the cell,
        /// so the cell's own inset is included, which a measurement of the bare string misses.
        public func wrappedTextHeight(width: CGFloat) -> CGFloat {
            guard let cell else { return font?.wrappedTextHeight(for: stringValue, width: width) ?? frame.height }

            return cell.cellSize(forBounds: CGRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude)).height
        }
    }

#endif
