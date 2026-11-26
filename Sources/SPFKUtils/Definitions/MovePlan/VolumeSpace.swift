// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKBase
import SPFKFileSystem

/// A volume's free space and whether it clones, as read at one moment.
public struct VolumeSpace: Sendable, Hashable {
    /// Free bytes, or nil when the volume did not answer.
    public let availableCapacity: Int64?

    /// A copy within the volume is a clone, which writes no data.
    public let supportsCloning: Bool

    /// The volume's name as Finder shows it.
    public let name: String?

    public init(availableCapacity: Int64?, supportsCloning: Bool, name: String?) {
        self.availableCapacity = availableCapacity
        self.supportsCloning = supportsCloning
        self.name = name
    }

    /// Free bytes from the two capacity keys: the larger, since important-usage counts purgeable
    /// space on the system volume but answers 0 on external APFS and HFS+ volumes.
    public static func availableCapacity(importantUsage: Int64?, available: Int?) -> Int64? {
        switch (importantUsage, available.map(Int64.init)) {
        case let (important?, available?): max(important, available)
        case let (important, available): important ?? available
        }
    }

    /// The space of the volume holding `url`; a volume that cannot answer reads as unknown.
    public static func read(at url: URL) -> VolumeSpace {
        do {
            let values = try url.resourceValues(forKeys: [
                .volumeAvailableCapacityForImportantUsageKey, .volumeAvailableCapacityKey,
                .volumeSupportsFileCloningKey, .volumeLocalizedNameKey,
            ])
            let available = availableCapacity(
                importantUsage: values.volumeAvailableCapacityForImportantUsage,
                available: values.volumeAvailableCapacity
            )
            return VolumeSpace(availableCapacity: available, supportsCloning: values.volumeSupportsFileCloning ?? false, name: values.volumeLocalizedName)
        } catch {
            Log.error("Couldn't read the free space of \(url.lastPathComponent)", error)
            return VolumeSpace(availableCapacity: nil, supportsCloning: false, name: nil)
        }
    }
}

/// The bytes a copy writes on one volume, against that volume's free space.
public struct CopySpaceNeed: Sendable, Hashable {
    public let bytes: UInt64
    public let availableCapacity: Int64?
    public let volumeName: String?

    public init(bytes: UInt64, availableCapacity: Int64?, volumeName: String?) {
        self.bytes = bytes
        self.availableCapacity = availableCapacity
        self.volumeName = volumeName
    }

    /// Whether the copy needs more than the volume has free. Unread space is never short.
    public var isShort: Bool {
        guard let availableCapacity else { return false }
        return bytes > UInt64(max(0, availableCapacity))
    }
}

#if os(macOS)
extension MovePlanBuilder {
    /// Each volume copying `plan` writes data to. Under a folder template that is the root's, as
    /// read when it was chosen; beside the sources it is each source volume, read through
    /// `sourceVolumeSpace` with one of its source folders. A volume needing nothing is left out.
    public func copySpaceNeeds(
        _ plan: MovePlan,
        placement: FolderPlacement,
        sourceVolumeSpace: (URL) -> VolumeSpace = VolumeSpace.read(at:)
    ) -> [CopySpaceNeed] {
        if case let .template(_, root) = placement {
            let bytes = bytesToCopy(plan, root: root)
            return bytes > 0 ? [CopySpaceNeed(bytes: bytes, availableCapacity: root.availableCapacity, volumeName: root.volumeName)] : []
        }

        var order: [URL?] = []
        var byVolume: [URL?: (folder: URL, bytes: UInt64)] = [:]

        for input in plannedInputs(plan) {
            if byVolume[input.volume] == nil {
                order.append(input.volume)
                byVolume[input.volume] = (input.url.deletingLastPathComponent(), 0)
            }

            byVolume[input.volume]?.bytes += input.fileSize ?? 0
        }

        return order.compactMap { volume in
            guard let entry = byVolume[volume] else { return nil }

            let space = sourceVolumeSpace(entry.folder)
            guard !space.supportsCloning, entry.bytes > 0 else { return nil }

            return CopySpaceNeed(bytes: entry.bytes, availableCapacity: space.availableCapacity, volumeName: space.name)
        }
    }

    /// The summed size of `plan`'s planned files. Companions are not counted.
    public func totalBytes(of plan: MovePlan) -> UInt64 {
        plannedInputs(plan).reduce(0) { $0 + ($1.fileSize ?? 0) }
    }

    private func plannedInputs(_ plan: MovePlan) -> [MovePlanInput] {
        plan.groups.compactMap { group in indexByURL[group.source].map { prepared[$0].input } }
    }
}
#endif

extension MoveRoot {
    /// This root with its volume's space as given rather than as read, for a check against known
    /// figures.
    public func replacingSpace(_ space: VolumeSpace) -> MoveRoot {
        MoveRoot(
            url: url,
            volume: volume,
            isCaseSensitive: isCaseSensitive,
            availableCapacity: space.availableCapacity,
            supportsCloning: space.supportsCloning,
            volumeName: space.name
        )
    }
}
