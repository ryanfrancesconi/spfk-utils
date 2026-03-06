// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

extension URL {
    /// Extracts a query string parameter value from this URL.
    /// - Parameter param: The query parameter name.
    /// - Returns: The parameter value, or `nil` if not found.
    public func queryStringParameter(_ param: String) -> String? {
        guard let components = URLComponents(string: absoluteString) else { return nil }
        return components.queryItems?.first(where: { $0.name == param })?.value
    }
}
