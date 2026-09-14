// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKFileSystem
import SPFKImage

extension ImageConversionSource: FileConversionWork {
    public var conflictScheme: FileConflictScheme {
        get { options.conflictScheme }
        set { options.conflictScheme = newValue }
    }
}
