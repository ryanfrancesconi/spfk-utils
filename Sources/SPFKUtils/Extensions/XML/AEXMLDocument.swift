// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import AEXML
import Foundation

extension AEXMLDocument {
    public convenience init(fromString string: String) throws {
        var options = AEXML.AEXMLOptions()
        options.parserSettings.shouldTrimWhitespace = true

        // check for bad characters here...
        let string = string.removing(.controlCharacters)

        try self.init(xml: string,
                      encoding: .utf8,
                      options: options)
    }
}
