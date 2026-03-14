// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import Foundation
import SPFKBase
    import SPFKTesting
    import SPFKUtils
    import Testing

    @Suite(.serialized)
    class BundleResourcesTests: BinTestCase {
        var tmpfile: URL?

        override public init() async {
            await super.init()
            tmpfile = try? copyToBin(url: TestBundleResources.shared.mp3_no_metadata)
        }

        deinit {
            removeBin()
            #expect(tmpfile?.exists == false)
        }

        @Test func testBin() async throws {
            #expect(tmpfile?.exists == true)
        }

        @Test func testBundle() async throws {
            let bundle = TestBundleResources.shared
            #expect(bundle.bundleURL.exists)
        }
    }
#endif
