// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

public enum StereoState: String {
    /// Channels are displayed and played normally
    case normal

    /// Channel order is reversed, L-R becomes R-L, or 123 becomes 321
    case flipped

    /// Channels are mixed to mono
    case mono
}
