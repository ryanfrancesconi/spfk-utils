// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

extension Dictionary {
    /// Merges the dictionary with dictionaries passed. The latter dictionaries will override
    /// values of the keys that are already set
    ///
    /// - parameter dictionaries: A comma separated list of dictionaries
    public mutating func merge(dictionaries: Dictionary...) {
        for dict in dictionaries {
            for (key, value) in dict {
                updateValue(value, forKey: key)
            }
        }
    }
}
