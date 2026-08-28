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

        /// Why the file refuses a write, or that it does not.
        ///
        /// Mutable, like ``finderTags`` and unlike everything else here, because it is edited
        /// rather than only observed: a `var` holds the state the user has asked for, and the save
        /// applies it. Between the edit and the save this differs from the file, which is the same
        /// contract every other pending edit has.
        ///
        /// Recorded so a row on an unmounted volume still shows what the library last knew.
        /// **Never the value a write guard consults** -- `URL.lockState` re-reads the file, so a
        /// pending or stale value can neither let a bad write through nor block a good one.
        public var lockState: FileLockState

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
            lockState = url.lockState

            initialize()
        }

        /// Rebuilds a previously captured set of properties without touching the file.
        ///
        /// For a store that persists these as columns rather than as an encoded document: every
        /// stored property here is `private(set)`, so a backend outside this module has no other
        /// way to put the values back. ``init(url:)`` is not a substitute — it re-reads the file,
        /// which answers the wrong question for a file on a volume that is no longer mounted.
        ///
        /// `fileSizeString` is derived from `fileSize` here, exactly as it is on every other path.
        public init(
            url: URL,
            finderTags: FinderTagGroup,
            creationDate: Date?,
            fileSize: UInt64?,
            modificationState: FileModificationState,
            lockState: FileLockState
        ) {
            self.url = url
            self.finderTags = finderTags
            self.creationDate = creationDate
            self.fileSize = fileSize
            self.modificationState = modificationState
            self.lockState = lockState

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
            case lockState
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            url = try container.decode(URL.self, forKey: .url)
            finderTags = try container.decodeIfPresent(FinderTagGroup.self, forKey: .finderTags) ?? FinderTagGroup()
            creationDate = try container.decodeIfPresent(Date.self, forKey: .creationDate)
            fileSize = try container.decodeIfPresent(UInt64.self, forKey: .fileSize)

            // Absent from every record written before the lock state existed, and `.writable` is
            // the right reading of that: nothing was known to be in the way. The value is a
            // display cache -- a write guard re-reads the file -- so a wrong one costs a stale row
            // rather than a lost or admitted write.
            lockState = try container.decodeIfPresent(FileLockState.self, forKey: .lockState) ?? .writable

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
            try container.encode(lockState, forKey: .lockState)

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
