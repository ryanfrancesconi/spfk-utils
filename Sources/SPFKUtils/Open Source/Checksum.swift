// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Checksum
import Foundation

extension Checksumable {
    public func checksum(
        algorithm: DigestAlgorithm,
        chunkSize: Chunksize = .normal,
        queue: DispatchQueue = .main,
        progress: ProgressHandler? = nil
    ) async throws -> Result<String, ChecksumError> {
        try await withCheckedThrowingContinuation { continuation in
            checksum(algorithm: algorithm, chunkSize: chunkSize, queue: queue, progress: progress) { result in
                continuation.resume(returning: result)
            }
        }
    }
}
