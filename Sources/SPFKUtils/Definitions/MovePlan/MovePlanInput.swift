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

    /// The mount point of the file's volume, from ``MoveRoot/volume(of:)``. Nil when unread, which
    /// no root refuses.
    public var volume: URL?

    /// Read once with the selection. Duplicate candidates are equal in size, and a copy's bytes
    /// are summed from it.
    public var fileSize: UInt64?

    /// The row shows edits not yet saved, which a copy has written onto it.
    public var hasUnsavedEdits = false

    public init(
        url: URL,
        values: [String: NameTemplate.Value],
        isLocked: Bool = false,
        isBusy: Bool = false,
        isMissing: Bool = false,
        isFolderWritable: Bool = true,
        isInsidePackage: Bool = false,
        volume: URL? = nil,
        fileSize: UInt64? = nil
    ) {
        self.url = url
        self.values = values
        self.isLocked = isLocked
        self.isBusy = isBusy
        self.isMissing = isMissing
        self.isFolderWritable = isFolderWritable
        self.isInsidePackage = isInsidePackage
        self.volume = volume
        self.fileSize = fileSize
    }
}
