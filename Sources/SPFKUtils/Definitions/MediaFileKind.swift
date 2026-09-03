// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import UniformTypeIdentifiers

/// Which technical-data domain a media file belongs to. The two blocks are disjoint — EXIF against
/// AVFoundation/QuickTime — so a consumer populates and reads one or the other.
///
/// **The `String` raw values are on-disk schema.** They are persisted in SQLite (`element_media.kind`)
/// and in JSON, and one query binds `.video.rawValue` into raw SQL, so renaming a case is a
/// migration rather than a rename.
public enum MediaFileKind: String, Sendable, Codable {
    case image
    case video
}

extension MediaFileKind {
    /// By UTType conformance rather than an extension list, so the accepted set follows the
    /// system's. `nil` for a file that is neither.
    ///
    /// A path-extension answer, which is what a caller holding only a URL can have. It reports an
    /// audio-only `.mp4`/`.mov` as `.video`; anything needing to know whether a video *track* is
    /// actually present asks `VideoTrackReader` instead.
    public init?(url: URL) {
        guard let type = UTType(filenameExtension: url.pathExtension) else { return nil }

        if type.conforms(to: .movie) {
            self = .video
        } else if type.conforms(to: .image) {
            self = .image
        } else {
            return nil
        }
    }
}
