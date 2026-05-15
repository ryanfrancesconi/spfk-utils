// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import AppKit
    import SPFKBase

    extension NSFont {
        /// The font's natural line height (no string required). Use for row heights, text field
        /// sizing, and anywhere you need a consistent vertical metric for a given font.
        /// Result is pixel-rounded (`.int.cgFloat`).
        public var fontHeight: CGFloat {
            boundingRectForFont.size.height.int.cgFloat
        }

        /// The single-line pixel size of a string at this font. Use when you need both width and
        /// height for a specific string. Not rounded — use the raw value for layout math, or
        /// `width(for:)` when you only need the width.
        public func size(for string: String) -> CGSize {
            string.size(withAttributes: [.font: self])
        }

        /// Convenience for `size(for:).width`, pixel-rounded. Use for column sizing and label
        /// widths where the height is already known from `fontHeight`.
        public func width(for string: String) -> CGFloat {
            size(for: string).width.int.cgFloat
        }

        /// The height a string needs when word-wrapped at a fixed pixel width. Use for
        /// notification rows, tooltips, or any view that must fit multi-line text.
        /// Delegates to `NSAttributedString.height(withConstrainedWidth:)`.
        public func wrappedTextHeight(for string: String, width: CGFloat) -> CGFloat {
            NSAttributedString(string: string, attributes: [.font: self])
                .height(withConstrainedWidth: width)
        }
    }

    extension NSFont {
        /// Utility to create a font from a URL such as inside a package
        ///
        /// - Parameters:
        ///   - url: `URL` to the font
        ///   - ofSize: the size to create it at
        /// - Returns: `NSFont` or nil
        public static func create(from url: URL, ofSize: CGFloat) -> NSFont? {
            guard let data = NSData(contentsOf: url),
                  let provider = CGDataProvider(data: data),
                  let ref = CGFont(provider)
            else {
                Log.error("Couldn't create font")
                return nil
            }

            return CTFontCreateWithGraphicsFont(ref, ofSize, nil, nil)
        }
    }

    extension NSFont {
        public static func systemFont(
            controlSize: NSControl.ControlSize,
            traits: NSFontDescriptor.SymbolicTraits = []
        ) -> NSFont? {
            let size = NSFont.systemFontSize(for: .regular)

            let descriptor = NSFont.systemFont(ofSize: size)
                .fontDescriptor
                .withSymbolicTraits(traits)

            return NSFont(descriptor: descriptor, size: size)
        }
    }

    @MainActor
    extension NSFont {
        public static let miniSystemFont = NSFont.systemFont(
            ofSize: NSFont.systemFontSize(for: .mini)
        )

        public static let miniBoldSystemFont = NSFont.boldSystemFont(
            ofSize: NSFont.systemFontSize(for: .mini)
        )

        public static let smallSystemFont = NSFont.systemFont(
            ofSize: NSFont.systemFontSize(for: .small)
        )

        public static let regularSystemFont = NSFont.systemFont(
            ofSize: NSFont.systemFontSize(for: .regular)
        )

        public static let regularBoldSystemFont = NSFont.boldSystemFont(
            ofSize: NSFont.systemFontSize(for: .regular)
        )

        public static let regularItalicSystemFont = NSFont.systemFont(
            controlSize: .regular, traits: [.italic]
        )

        public static let regularMonoSpacedFont: NSFont? = NSFont(
            name: "Monaco",
            size: NSFont.systemFontSize(for: .regular)
        )

        public static let smallMonoSpacedFont: NSFont? = NSFont(
            name: "Monaco",
            size: NSFont.systemFontSize(for: .small)
        )

        public static let smallBoldSystemFont = NSFont.boldSystemFont(
            ofSize: NSFont.systemFontSize(for: .small)
        )

        public static let largeSystemFont = NSFont.systemFont(
            ofSize: NSFont.systemFontSize(for: .large)
        )

        public static let largeBoldSystemFont = NSFont.boldSystemFont(
            ofSize: NSFont.systemFontSize(for: .large)
        )

        public static let headerSystemFont = NSFont.systemFont(ofSize: 14)
    }
#endif
