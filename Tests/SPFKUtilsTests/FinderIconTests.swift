// Copyright Ryan Francesconi. All Rights Reserved.

#if os(macOS)

    import AppKit
    import Foundation
    import Testing

    @testable import SPFKUtils

    /// `FinderIcon.fileType(for:)` is called per row per reload by both products' tables, so it resolves
    /// from the path extension and never touches the file system.
    @Suite
    @MainActor
    struct FinderIconTests {
        private func url(_ name: String) -> URL {
            URL(fileURLWithPath: "/tmp/finder-icon-tests/\(name)")
        }

        /// The file need not exist — that is the whole point, since a row is drawn for a missing file
        /// as readily as a present one.
        @Test func resolvesAnIconForAKnownExtensionWithoutTheFile() {
            #expect(NSWorkspace.FinderIcon.fileType(for: url("nothing-here.jpg")) != nil)
        }

        @Test func isCaseInsensitiveOnTheExtension() {
            let lower = NSWorkspace.FinderIcon.fileType(for: url("a.jpg"))
            let upper = NSWorkspace.FinderIcon.fileType(for: url("b.JPG"))
            #expect(lower === upper)
        }

        /// Cached by extension, so the second row of a given type costs a dictionary lookup. Identity,
        /// not equality — a fresh `NSImage` each time would compare equal and still allocate.
        @Test func cachesByExtensionAcrossDifferentFiles() {
            let first = NSWorkspace.FinderIcon.fileType(for: url("one.png"))
            let second = NSWorkspace.FinderIcon.fileType(for: url("two.png"))
            #expect(first != nil)
            #expect(first === second)
        }

        /// **Nil is a real outcome, not an error path** — a file with no extension has no type to
        /// resolve, which is why every caller needs a fallback image behind this.
        @Test func returnsNilForAnExtensionlessName() {
            #expect(NSWorkspace.FinderIcon.fileType(for: url("README")) == nil)
        }

        /// An unknown extension still resolves — `UTType(filenameExtension:)` synthesizes a dynamic
        /// type, so the caller gets a generic document icon rather than nil. **An empty extension is
        /// the only nil**, which is what bounds the fallback above.
        @Test func anUnrecognizedExtensionStillResolvesToAGenericIcon() {
            #expect(NSWorkspace.FinderIcon.fileType(for: url("a.spfk-not-a-real-type")) != nil)
        }

        /// The generic fallbacks the callers reach for when the above is nil.
        @Test func theGenericFallbackIconsResolve() {
            #expect(NSWorkspace.FinderIcon.image != nil)
        }
    }

#endif
