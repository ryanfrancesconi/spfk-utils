// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// Where a run puts each file: in its own folder, or in folders a template renders, under a root
/// or under each file's own folder.
public enum FolderPlacement: Sendable, Hashable {
    case keepCurrent

    /// Each level of the template is one folder under the root, rendered from the file's values.
    /// A template rendering no level puts the file in the root itself.
    case template(NameTemplate, root: MoveRoot)

    /// Each file's levels rendered under its own folder. A folder already ending in a leading run
    /// of the levels takes the rest of them only.
    case underEachFolder(NameTemplate)

    /// Whether files are filed into folders a template renders.
    public var placesFolders: Bool {
        self != .keepCurrent
    }
}
