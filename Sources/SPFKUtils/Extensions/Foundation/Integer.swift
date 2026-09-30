// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

extension Int {
    public func incremented(by value: Int = 1) -> Int {
        self + value
    }

    public func decremented(by value: Int = 1) -> Int {
        self - value
    }
}
