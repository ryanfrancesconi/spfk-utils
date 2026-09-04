// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// Persists the last user-chosen directory URL for each panel type so that
/// NSOpenPanel and NSSavePanel reopen in the same location across sessions.
///
/// The stored URL is always a directory (file selection panels store the parent
/// directory). Setting `NSOpenPanel.directoryURL` to a path outside the sandbox
/// is safe — the panel runs via the OS powerbox and can navigate anywhere.
///
/// One key set for both products; a key a product never writes costs it nothing.
public struct PanelDirectoryCache: Sendable, Hashable, Equatable, Codable {
    // MARK: - Keys

    public enum Key: String, Codable, CaseIterable, Sendable {
        /// Add files / directories to the current playlist or album.
        case addFiles
        /// External-format import — decrypted output directory.
        case addImportDestination
        /// Audio format conversion — destination directory.
        case fileConversion
        /// Image export — destination directory.
        case imageExport
        /// CSV export — save location.
        case csvExport
        /// UCS rename copy — destination directory.
        case ucsRename
        /// Export Soundpack — destination directory.
        case soundpackExport
        /// Segment render — output directory.
        case segmentRenderOutput
        /// Import Photos Library — the folder holding the `.photoslibrary` last chosen.
        case photosLibrary
    }

    // MARK: - Storage

    /// Stored as [String: URL] so Codable synthesizes a plain JSON object.
    private var urls: [String: URL]

    // MARK: - Init

    public init(urls: [String: URL] = [:]) {
        self.urls = urls
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        urls = try container.decodeIfPresent([String: URL].self, forKey: .urls) ?? [:]
    }

    // MARK: - Access

    public subscript(_ key: Key) -> URL? {
        get { urls[key.rawValue] }
        set { urls[key.rawValue] = newValue }
    }
}
