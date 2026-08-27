// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

/// Identifies which variant of a cached image to read or write.
public enum CachedImageType: Sendable {
    /// PNG thumbnail, at whatever size the caller supplies.
    case thumbnail
    /// Full-resolution image (JPEG or PNG, depending on source).
    case fullQuality
}
