// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKBase
import SPFKFileSystem
import SPFKTesting
import Testing

@testable import SPFKUtils

@Suite(.tags(.file))
final class BatchFileConverterTests: BinTestCase {
    private struct Work: FileConversionWork {
        var input: URL
        var output: URL
        var originalInput: URL?
        var conflictScheme: FileConflictScheme = .overwrite
    }

    private struct ConversionFailure: Error {}

    private actor Recorder {
        var converted: [String] = []
        var progress: [(completed: Int, total: Int)] = []

        func convert(_ name: String) { converted.append(name) }
        func report(_ completed: Int, _ total: Int) { progress.append((completed, total)) }
    }

    private func work(_ name: String, scheme: FileConflictScheme = .overwrite) -> Work {
        Work(
            input: bin.appending(component: "in-\(name)", directoryHint: .notDirectory),
            output: bin.appending(component: name, directoryHint: .notDirectory),
            conflictScheme: scheme
        )
    }

    @Test func anEmptyBatchThrows() async {
        await #expect(throws: (any Error).self) {
            _ = try await BatchFileConverter<Work>([]).start { $0 }
        }
    }

    /// The window takes each result as it finishes, so completion order is not input order. The
    /// first item is the slowest here.
    @Test func resultsComeBackInInputOrder() async throws {
        let items = ["slow", "b", "c", "d"].map { work($0) }

        let results = try await BatchFileConverter(items).start { item in
            if item.output.lastPathComponent == "slow" {
                try await Task.sleep(seconds: 0.2)
            }
            return item
        }

        #expect(results.map(\.work.output) == items.map(\.output))
    }

    @Test func aFailureIsIsolatedToItsItem() async throws {
        let items = ["a", "fail", "c"].map { work($0) }

        let results = try await BatchFileConverter(items).start { item in
            guard item.output.lastPathComponent != "fail" else { throw ConversionFailure() }
            return item
        }

        #expect(results.map { $0.error != nil } == [false, true, false])
    }

    /// A converter checking the disk for a free name would hand both of these the same one, since
    /// neither has written anything yet when the other looks.
    @Test func uniqueOutputsAreSettledBeforeAnythingConverts() async throws {
        let taken = bin.appending(component: "song.out", directoryHint: .notDirectory)
        try Data().write(to: taken)

        let items = [work("song.out", scheme: .unique), work("song.out", scheme: .unique)]

        let results = try await BatchFileConverter(items).start { $0 }
        let outputs = results.map(\.work.output)

        #expect(Set(outputs).count == 2)
        #expect(!outputs.contains(taken))
        #expect(results.allSatisfy { $0.work.conflictScheme == .overwrite })
    }

    @Test func aUniqueOutputWhoseFolderCannotBeCreatedFailsWithoutConverting() async throws {
        let blocker = bin.appending(component: "blocker", directoryHint: .notDirectory)
        try Data().write(to: blocker)

        var blocked = work("blocked", scheme: .unique)
        blocked.output = blocker.appending(component: "blocked.out", directoryHint: .notDirectory)

        let recorder = Recorder()
        let results = try await BatchFileConverter([blocked, work("ok", scheme: .unique)]).start { item in
            await recorder.convert(item.output.lastPathComponent)
            return item
        }

        #expect(results.map { $0.error != nil } == [true, false])
        #expect(await recorder.converted == ["ok"])
    }

    @Test func progressReportsEachItemOnce() async throws {
        let items = ["a", "b", "fail"].map { work($0) }
        let recorder = Recorder()

        _ = try await BatchFileConverter(items, batchSize: 2).start(
            progress: { completed, total, _ in await recorder.report(completed, total) },
            convert: { item in
                guard item.output.lastPathComponent != "fail" else { throw ConversionFailure() }
                return item
            }
        )

        let progress = await recorder.progress
        #expect(progress.map(\.completed).sorted() == [1, 2, 3])
        #expect(progress.allSatisfy { $0.total == 3 })
    }

    @Test func cancellingStopsTheBatch() async {
        let items = ["a", "b", "c"].map { work($0) }

        let task = Task {
            try await BatchFileConverter(items, batchSize: 1).start { item in
                try await Task.sleep(seconds: 5)
                return item
            }
        }

        task.cancel()

        await #expect(throws: CancellationError.self) {
            _ = try await task.value
        }
    }
}
