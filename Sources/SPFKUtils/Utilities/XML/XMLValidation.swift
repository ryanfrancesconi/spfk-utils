// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import AEXML
import Foundation

/// Well-formedness check for XML text such as an XMP packet or an iXML chunk.
public enum XMLValidation {
    public enum Result: Sendable, Equatable {
        /// Well-formed; carries the document re-serialized with standard indentation.
        case valid(prettyPrinted: String)
        case invalid(errorDescription: String)
    }

    public static func validate(string: String) -> Result {
        do {
            let doc = try AEXMLDocument(xml: string)
            return .valid(prettyPrinted: doc.xml)
        } catch {
            return .invalid(errorDescription: parserErrorDescription(error))
        }
    }

    /// "XML parse error:" plus the line and column, since the `XMLParser` error AEXML throws
    /// carries no reason text and its `localizedDescription` names only the domain and code.
    private static func parserErrorDescription(_ error: Error) -> String {
        let nsError = error as NSError

        guard nsError.domain == XMLParser.errorDomain else {
            return error.localizedDescription
        }

        let line = nsError.userInfo["NSXMLParserErrorLineNumber"] as? Int
        let column = nsError.userInfo["NSXMLParserErrorColumn"] as? Int

        var message = "XML parse error:"

        if let line {
            message += " (line \(line)"
            if let column {
                message += ", column \(column)"
            }
            message += ")"
        }

        return message
    }
}
