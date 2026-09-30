// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

// MARK: - Common Date string formatting

fileprivate let dateStyleLong: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .long
    dateFormatter.timeStyle = .long
    dateFormatter.locale = .current
    return dateFormatter
}()

fileprivate let dateStyleSimple: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMM d, h:mm a"
    dateFormatter.locale = .current
    return dateFormatter
}()

fileprivate let dateStyleMedium: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .short
    dateFormatter.locale = .current
    return dateFormatter
}()

fileprivate let dateStyleNoTime: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .long
    dateFormatter.timeStyle = .none
    dateFormatter.locale = .current
    return dateFormatter
}()

extension Date {
    public var longString: String { // formattedString
        dateStyleLong.string(from: self)
    }

    public var mediumString: String {
        dateStyleMedium.string(from: self)
    }

    public var simpleString: String {
        dateStyleSimple.string(from: self)
    }

    public var onlyDateString: String {
        dateStyleNoTime.string(from: self)
    }
}
