// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// One file of a run as the plan builder sees it, read once when the run is set up so a re-render
/// never reaches back to the element or the disk.
public struct MovePlanInput: Sendable, Hashable {
    public var url: URL

    /// The file's token values, `name` and `ext` among them.
    public var values: [String: NameTemplate.Value]

    public var isLocked: Bool
    public var isBusy: Bool
    public var isMissing: Bool
    public var isFolderWritable: Bool

    /// Inside a bundle or a Photos library, whose layout belongs to the app that owns it.
    public var isInsidePackage: Bool

    public init(
        url: URL,
        values: [String: NameTemplate.Value],
        isLocked: Bool = false,
        isBusy: Bool = false,
        isMissing: Bool = false,
        isFolderWritable: Bool = true,
        isInsidePackage: Bool = false
    ) {
        self.url = url
        self.values = values
        self.isLocked = isLocked
        self.isBusy = isBusy
        self.isMissing = isMissing
        self.isFolderWritable = isFolderWritable
        self.isInsidePackage = isInsidePackage
    }
}
