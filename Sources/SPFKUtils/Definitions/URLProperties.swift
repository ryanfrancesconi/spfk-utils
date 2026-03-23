// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import Foundation
    import SPFKFileSystem

    public struct URLProperties: Hashable, Sendable {
        public private(set) var url: URL
        public var finderTags: FinderTagGroup
        public private(set) var creationDate: Date?
        public private(set) var modificationDate: Date?
        public private(set) var fileSize: UInt64?
        public private(set) var fileSizeString: String?

        public var isModified: Bool {
            url.modificationDate != modificationDate
        }

        public init(url: URL) {
            self.url = url
            creationDate = url.creationDate
            modificationDate = url.modificationDate
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
            case modificationDate
            case fileSize
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            url = try container.decode(URL.self, forKey: .url)
            finderTags = try container.decodeIfPresent(FinderTagGroup.self, forKey: .finderTags) ?? FinderTagGroup()
            creationDate = try container.decodeIfPresent(Date.self, forKey: .creationDate)
            modificationDate = try container.decodeIfPresent(Date.self, forKey: .modificationDate)
            fileSize = try container.decodeIfPresent(UInt64.self, forKey: .fileSize)
            initialize()
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(url, forKey: .url)
            try container.encode(finderTags, forKey: .finderTags)
            try container.encodeIfPresent(creationDate, forKey: .creationDate)
            try container.encodeIfPresent(modificationDate, forKey: .modificationDate)
            try container.encodeIfPresent(fileSize, forKey: .fileSize)
        }
    }

#endif
