// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// The run state of a ``TimerModel``.
public enum TimerState {
    /// The timer is paused and not firing.
    case suspended

    /// The timer is actively firing at its configured interval.
    case resumed
}
