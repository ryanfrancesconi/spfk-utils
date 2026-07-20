// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

public enum LabelAlignment: Int, Codable, CaseIterable, Sendable {
    case left = 0
    case right = 1
}

#if canImport(AppKit)
    import AppKit
    import QuartzCore

    extension LabelAlignment {
        public var layerAlignmentMode: CATextLayerAlignmentMode {
            self == .right ? .right : .left
        }

        public var textAlignment: NSTextAlignment { .left }
    }
#endif
