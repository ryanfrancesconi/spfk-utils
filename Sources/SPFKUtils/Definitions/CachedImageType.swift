// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

/// Identifies which variant of a cached image to read or write.
public enum CachedImageType: Sendable, Hashable {
    /// PNG thumbnail, at whatever size the caller supplies.
    case thumbnail
    /// Full-resolution image (JPEG or PNG, depending on source).
    case fullQuality
    /// A PNG thumbnail of the file shown another way, such as through a develop. A file keeps one per
    /// variant beside its plain thumbnail, and dropping the file drops them all.
    case thumbnailVariant(CachedImageVariant)
}

/// Names a ``CachedImageType/thumbnailVariant(_:)``. It becomes part of a file name, so only ASCII
/// letters and digits are accepted.
public struct CachedImageVariant: Sendable, Hashable {
    public let name: String

    public init(_ name: String) throws {
        guard !name.isEmpty, name.utf8.allSatisfy({ $0.isASCIIAlphanumeric }) else {
            throw CachedImageVariantError.invalidName(name)
        }

        self.name = name
    }
}

public enum CachedImageVariantError: Error, Equatable {
    case invalidName(String)
}

extension UInt8 {
    fileprivate var isASCIIAlphanumeric: Bool {
        (UInt8(ascii: "a") ... UInt8(ascii: "z")).contains(self)
            || (UInt8(ascii: "A") ... UInt8(ascii: "Z")).contains(self)
            || (UInt8(ascii: "0") ... UInt8(ascii: "9")).contains(self)
    }
}
