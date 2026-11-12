// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKBench
import SPFKImage
import SPFKUtils
import UniformTypeIdentifiers

// A fixed set of conversions of the corpus, written as JSON for comparison against a stored
// baseline. A case id is never renamed and a case is never reshaped without starting a new
// baseline. Each case's count is the outputs written; its note carries the peak footprint.
//
// The corpus names each file `<kind>-<nnn>-<original name>`, which is how a case picks its inputs.

enum RegressionSuite {
    private struct Case {
        let slug: String
        /// File name prefixes a case converts; empty for every file.
        let kinds: [String]
        let type: UTType
        var maxPixelSize: Int?
        /// The first this many inputs, for a case slow enough to dominate the run.
        var limit: Int?
    }

    private static let cases: [Case] = [
        Case(slug: "jpeg-to-heic", kinds: ["jpg-"], type: .heic),
        Case(slug: "mixed-to-jpeg-2048", kinds: [], type: .jpeg, maxPixelSize: 2048),
        Case(slug: "heic-to-png", kinds: ["heic-"], type: .png, limit: 32),
    ]

    static var caseIDs: [String] {
        cases.map { "convert.\($0.slug)" }
    }

    static func run() async -> RegressionRun {
        var run = RegressionRun(bench: "image-conversion")

        guard let path = ProcessInfo.processInfo.environment["IMAGE_CONVERSION_CORPUS"] else {
            for id in caseIDs { run.skip(id, note: "IMAGE_CONVERSION_CORPUS unset") }
            return run
        }

        let scratch = FileManager.default.temporaryDirectory
            .appending(component: "spfk-image-conversion-bench-\(UUID().uuidString)", directoryHint: .isDirectory)

        defer {
            do {
                try FileManager.default.removeItem(at: scratch)
            } catch {
                FileHandle.standardError.write(Data("could not remove \(scratch.path): \(error)\n".utf8))
            }
        }

        do {
            let files = try FileManager.default
                .contentsOfDirectory(at: URL(fileURLWithPath: path), includingPropertiesForKeys: nil)
                .filter { $0.pathExtension != "json" && !$0.lastPathComponent.hasPrefix(".") }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }

            for item in cases {
                await measure(item, files: files, into: &run, scratch: scratch)
            }
        } catch {
            let recorded = Set(run.cases.map(\.id))
            for id in caseIDs where !recorded.contains(id) {
                run.fail(id, note: "setup failed: \(error)")
            }
        }

        return run
    }

    private static func measure(_ item: Case, files: [URL], into run: inout RegressionRun, scratch: URL) async {
        let matching = item.kinds.isEmpty ? files : files.filter { file in
            item.kinds.contains { file.lastPathComponent.hasPrefix($0) }
        }
        let inputs = Array(matching.prefix(item.limit ?? matching.count))

        let directory = scratch.appending(component: item.slug, directoryHint: .isDirectory)
        let options = ImageConversionOptions(format: item.type.identifier, maxPixelSize: item.maxPixelSize)
        let pathExtension = item.type.preferredFilenameExtension ?? "img"

        let footprint = PeakFootprint()
        var startMB = Double.infinity
        var peakMB: Double = 0

        await run.measure("convert.\(item.slug)", iterations: 3, warmup: 1, prepare: {
            // Each iteration writes into an empty folder, so none measures replacing the last one's files.
            if FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.removeItem(at: directory)
            }
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            return inputs.map { input in
                ImageConversionSource(
                    input: input,
                    output: directory
                        .appending(component: input.deletingPathExtension().lastPathComponent, directoryHint: .notDirectory)
                        .appendingPathExtension(pathExtension),
                    options: options
                )
            }
        }, note: {
            String(format: "peak footprint %.0f MB from %.0f MB, %d inputs", peakMB, startMB, inputs.count)
        }) { work in
            startMB = min(startMB, footprintMB())
            footprint.start()
            defer { peakMB = max(peakMB, footprint.stop()) }

            let results = try await BatchFileConverter(work).start { item in
                try await ImageFormatConverter(source: item).convert()
            }

            return results.filter { $0.error == nil }.count
        }
    }
}
