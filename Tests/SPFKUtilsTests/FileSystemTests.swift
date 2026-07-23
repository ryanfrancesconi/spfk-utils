// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import Checksum
    import Foundation
import SPFKBase
    import SPFKTesting
    import SPFKUtils
    import Testing

    @Suite
    class FileSystemTests: BinTestCase {
        @Test func checksum() async throws {
            let url = TestBundleResources.shared.mp3_id3

            let result = try await url.checksum(algorithm: .md5)

            switch result {
            case let .success(checksum):
                Log.debug(checksum)

                #expect(checksum == "3bf405577fb19402d472ddfbaa0af827")

            case let .failure(error):
                throw error
            }
        }
    }
#endif
