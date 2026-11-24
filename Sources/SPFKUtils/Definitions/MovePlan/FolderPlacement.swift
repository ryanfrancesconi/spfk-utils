// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// Where a run puts each file: in its own folder, or under a root in folders a template renders.
public enum FolderPlacement: Sendable, Hashable {
    case keepCurrent

    /// Each level of the template is one folder under the root, rendered from the file's values.
    /// A template rendering no level puts the file in the root itself.
    case template(NameTemplate, root: MoveRoot)
}
