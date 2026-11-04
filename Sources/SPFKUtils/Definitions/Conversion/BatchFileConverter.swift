// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKBase
import SPFKFileSystem

/// Converts a batch of files concurrently, in one or more ``FileConversionPass``es.
///
/// Owns what is the same for every kind of file: settling output names before anything runs,
/// isolating each file's failure, and returning results in input order. The per-file converter owns
/// the rest, including refusing an output that is its own input and removing a partial output
/// on cancel.
public actor BatchFileConverter<Work: FileConversionWork> {
    public typealias Result = BatchFileConversionResult<Work>

    private let work: [Work]
    private let passes: [FileConversionPass]
    private var finishedCount = 0

    public init(_ work: [Work], batchSize: Int = FileConversionPass.defaultBatchSize) {
        self.init(work, passes: [FileConversionPass(indexes: Array(work.indices), batchSize: batchSize)])
    }

    /// An item no pass names fails rather than converting.
    public init(_ work: [Work], passes: [FileConversionPass]) {
        self.work = work
        self.passes = passes
    }

    /// Converts every item, returning a result for each in the order given.
    ///
    /// Cancelling stops new items, in this pass and every later one; those already running finish,
    /// and every item not run is `.failed` with `CancellationError`, so the results still hold one
    /// per item.
    ///
    /// - Parameters:
    ///   - progress: called as each item finishes, with how many have finished so far across every pass.
    ///   - convert: converts one item and returns it as converted. Runs concurrently.
    /// - Throws: on an empty batch.
    public func start(
        progress: (@Sendable (_ completed: Int, _ total: Int, _ result: Result) async -> Void)? = nil,
        convert: @escaping @Sendable (Work) async throws -> Work
    ) async throws -> [Result] {
        guard work.isNotEmpty else {
            throw NSError(description: "No files to process")
        }

        finishedCount = 0

        let work = work
        let resolved = Self.resolvingOutputs(work)

        var scheduled = Set<Int>()
        let passes: [(indexes: [Int], batchSize: Int)] = self.passes.map { pass in
            (indexes: pass.indexes.filter { work.indices.contains($0) && scheduled.insert($0).inserted }, batchSize: pass.batchSize)
        }

        let total = scheduled.count
        var finished: [(index: Int, result: Result)] = []

        for pass in passes where !Task.isCancelled {
            finished += await run(pass.indexes, batchSize: pass.batchSize, resolved: resolved, total: total, progress: progress, convert: convert)
        }

        let byIndex = Dictionary(finished.map { ($0.index, $0.result) }, uniquingKeysWith: { first, _ in first })

        return work.indices.map { index in
            if let result = byIndex[index] { return result }

            return .failed(
                work[index],
                scheduled.contains(index) ? CancellationError() : NSError(description: "\(work[index].input.lastPathComponent) is in no conversion pass")
            )
        }
    }

    private func run(
        _ indexes: [Int],
        batchSize: Int,
        resolved: [Swift.Result<Work, any Error>],
        total: Int,
        progress: (@Sendable (_ completed: Int, _ total: Int, _ result: Result) async -> Void)?,
        convert: @escaping @Sendable (Work) async throws -> Work
    ) async -> [(index: Int, result: Result)] {
        let work = work

        // batchMap appends as tasks finish, so each result carries the index it was asked for.
        return await batchMapKeepingFinished(count: indexes.count, batchSize: batchSize) { offset in
            let index = indexes[offset]
            let result: Result

            switch resolved[index] {
            case let .success(item):
                do {
                    result = try await .success(convert(item))
                } catch {
                    result = .failed(item, error)
                }

            case let .failure(error):
                result = .failed(work[index], error)
            }

            let completed = await self.didFinish()
            await progress?(completed, total, result)

            return (index: index, result: result)
        }
    }

    private func didFinish() -> Int {
        finishedCount += 1
        return finishedCount
    }

    /// Settles every output before anything converts, since concurrent conversions each checking
    /// the disk would claim the same free name.
    ///
    /// The first item claiming a path keeps it and its scheme, which decides what happens to a file
    /// already there. A `.unique` item, a later one claiming a path already claimed in this batch, or
    /// one naming another item's input, is numbered instead and its scheme becomes `.overwrite`, since
    /// the slot is now decided. A name is held in memory rather than claimed on disk, so an item the
    /// converter later refuses leaves nothing behind.
    static func resolvingOutputs(_ work: [Work]) -> [Swift.Result<Work, any Error>] {
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

        for (index, item) in work.enumerated() {
            for case let input? in [item.input, item.originalInput] {
                readers[key(input), default: []].insert(index)
            }
        }

        return work.enumerated().map { index, item in
            func isTaken(_ url: URL) -> Bool {
                let path = key(url)
                return claimed.contains(path) || readers[path, default: []].subtracting([index]).isNotEmpty
            }

            guard item.conflictScheme == .unique || isTaken(item.output) else {
                claimed.insert(key(item.output))
                return .success(item)
            }

            var item = item
            let resolved = FileSystem.nextAvailableURL(item.output, isTaken: isTaken)

            do {
                // The converter writes into this directory and does not create it.
                try FileManager.default.createDirectory(
                    at: resolved.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
            } catch {
                return .failure(error)
            }

            claimed.insert(key(resolved))

            item.output = resolved
            item.conflictScheme = .overwrite
            return .success(item)
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
