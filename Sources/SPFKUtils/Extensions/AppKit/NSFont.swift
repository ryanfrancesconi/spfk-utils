// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit

    extension NSFont {
        public var fontHeight: CGFloat {
            boundingRectForFont.size.height.int.cgFloat
        }

        public func size(for string: String) -> CGSize {
            string.size(withAttributes: [.font: self])
        }

        public func width(for string: String) -> CGFloat {
            size(for: string).width.int.cgFloat
        }

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
