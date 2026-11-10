// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKBase
import SPFKFileSystem

/// Settles a batch's output names in memory before any is written, since concurrent writers each
/// checking the disk would claim the same free name.
public enum BatchOutputClaims {
    /// One item's wanted output and the files it reads.
    public struct Claim: Sendable, Equatable {
        public var output: URL
        public var conflictScheme: FileConflictScheme
        public var inputs: [URL]

        public init(output: URL, conflictScheme: FileConflictScheme, inputs: [URL]) {
            self.output = output
            self.conflictScheme = conflictScheme
            self.inputs = inputs
        }
    }

    /// The first claim on a path keeps it and its scheme, which decides what happens to a file
    /// already there. A `.unique` claim, a later claim on a path already claimed, or one naming
    /// another item's input is numbered instead, and its scheme becomes `.overwrite`, since the slot
    /// is now decided. Paths compare case-insensitively where the volume does.
    ///
    /// - Parameter ownInputIsTaken: also numbers a claim naming its own input, so writing beside the
    ///   original never replaces it.
    /// - Returns: one result per claim, in order; a numbered claim whose folder cannot be created fails.
    public static func resolve(_ claims: [Claim], ownInputIsTaken: Bool = false) -> [Result<Claim, any Error>] {
        var claimed: Set<String> = []
        var caseSensitiveFolders: [URL: Bool] = [:]

        func key(_ url: URL) -> String {
            let folder = url.deletingLastPathComponent().standardizedFileURL
            let isCaseSensitive = caseSensitiveFolders[folder] ?? {
                let value = volumeIsCaseSensitive(at: folder)
                caseSensitiveFolders[folder] = value
                return value
            }()
            let path = url.standardizedFileURL.path
            return isCaseSensitive ? path : path.folding(options: [.caseInsensitive], locale: nil)
        }

        var readers: [String: Set<Int>] = [:]

        for (index, claim) in claims.enumerated() {
            for input in claim.inputs {
                readers[key(input), default: []].insert(index)
            }
        }

        return claims.enumerated().map { index, claim in
            func isTaken(_ url: URL) -> Bool {
                let path = key(url)
                let reading = readers[path, default: []]
                return claimed.contains(path) || (ownInputIsTaken ? reading : reading.subtracting([index])).isNotEmpty
            }

            guard claim.conflictScheme == .unique || isTaken(claim.output) else {
                claimed.insert(key(claim.output))
                return .success(claim)
            }

            var claim = claim
            let resolved = FileSystem.nextAvailableURL(claim.output, isTaken: isTaken)

            do {
                // The writer writes into this directory and does not create it.
                try FileManager.default.createDirectory(
                    at: resolved.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
            } catch {
                return .failure(error)
            }

            claimed.insert(key(resolved))

            claim.output = resolved
            claim.conflictScheme = .overwrite
            return .success(claim)
        }
    }

    /// Reads the nearest existing ancestor, since an output folder may not exist yet. An unreadable
    /// volume counts as case-insensitive, which can only number a name that needed none.
    private static func volumeIsCaseSensitive(at folder: URL) -> Bool {
        var folder = folder

        while !folder.exists, folder.path != "/" {
            folder = folder.deletingLastPathComponent()
        }

        do {
            let values = try folder.resourceValues(forKeys: [.volumeSupportsCaseSensitiveNamesKey])
            return values.volumeSupportsCaseSensitiveNames ?? false
        } catch {
            Log.error(folder, error)
            return false
        }
    }
}
