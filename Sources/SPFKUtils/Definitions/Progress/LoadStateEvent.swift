// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import SPFKBase

public enum LoadStateEvent {
    case loading(string: String?, progress: UnitInterval)
    case loaded
}
