// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import Foundation
    import SPFKFileSystem

    public struct URLProperties: Hashable, Sendable {
        public private(set) var url: URL
        public var finderTags: FinderTagGroup
        public private(set) var creationDate: Date?
        public private(set) var fileSize: UInt64?
        public private(set) var fileSizeString: String?

        /// When the file was last written, split by kind of change.
        ///
        /// Stored split rather than as one date because the two answer different questions, and
        /// collapsing them here is lossy in a way nothing downstream can undo: `finderTags` are
        /// extended attributes, so a Finder tag edit moves only the attribute date. A file
        /// observer comparing a single date can tell *that* the file changed but not whether
        /// re-reading its contents is warranted -- and for a photo library, that is the difference
        /// between reading an xattr and re-decoding EXIF, XMP and a video track.
        public private(set) var modificationState: FileModificationState

        /// When the file last changed, of either kind. Unchanged in meaning from when this was a
        /// stored property, so every existing display and sort call site reads the same value.
        public var modificationDate: Date? { modificationState.modificationDate }

        /// How the file on disk now differs from the state captured here, or `nil` if it doesn't.
        public var modification: FileModificationKind? {
            modificationState.change(to: FileModificationState(url: url))
        }

        public var isModified: Bool { modification != nil }

        public init(url: URL) {
            self.url = url
            creationDate = url.creationDate
            modificationState = FileModificationState(url: url)
            finderTags = FinderTagGroup(url: url)
            fileSize = url.regularFileAllocatedSize

            initialize()
        }

        private mutating func initialize() {
            if let fileSize {
                fileSizeString = ByteCount.toString(fileSize.int64)
            }
        }
    }

    extension URLProperties: Codable {
        enum CodingKeys: String, CodingKey {
            case url
            case finderTags
            case creationDate
            /// Written by versions that stored a single collapsed date. Read-only now -- see
            /// `init(from:)`.
            case modificationDate
            case contentModificationDate
            case attributeModificationDate
            case fileSize
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            url = try container.decode(URL.self, forKey: .url)
            finderTags = try container.decodeIfPresent(FinderTagGroup.self, forKey: .finderTags) ?? FinderTagGroup()
            creationDate = try container.decodeIfPresent(Date.self, forKey: .creationDate)
            fileSize = try container.decodeIfPresent(UInt64.self, forKey: .fileSize)

            // Data written before the split carries one collapsed date, which was the *later* of
            // the two. Only the content side is seeded from it: the attribute side stays nil so
            // `isClassifiable` is false and the first comparison after upgrading falls back to
            // comparing collapsed against collapsed -- the only comparison that value supports.
            //
            // **Do not seed both sides with it.** That makes the record look classifiable and
            // compares each half against a date it was never equal to, reporting a change for
            // every file whose two dates differ -- which is any file that was copied, tagged, or
            // quarantined. One persist replaces this with the real split values.
            let legacy = try container.decodeIfPresent(Date.self, forKey: .modificationDate)

            modificationState = FileModificationState(
                contentModificationDate: try container.decodeIfPresent(
                    Date.self, forKey: .contentModificationDate
                ) ?? legacy,
                attributeModificationDate: try container.decodeIfPresent(
                    Date.self, forKey: .attributeModificationDate
                )
            )

            initialize()
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(url, forKey: .url)
            try container.encode(finderTags, forKey: .finderTags)
            try container.encodeIfPresent(creationDate, forKey: .creationDate)
            try container.encodeIfPresent(fileSize, forKey: .fileSize)

            // The collapsed `modificationDate` key is deliberately not written back. It is
            // recoverable from either of these, and a library this size pays for every redundant
            // field once per element.
            try container.encodeIfPresent(
                modificationState.contentModificationDate, forKey: .contentModificationDate
            )
            try container.encodeIfPresent(
                modificationState.attributeModificationDate, forKey: .attributeModificationDate
            )
        }
    }

#endif
