// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// Describes the kind of timer to create via a timer factory.
public enum TimerType: Equatable {
    /// A main-thread `NSTimer` wrapper. Leeway is in milliseconds.
    case basic(timeInterval: TimeInterval = 1.0 / 30.0,
               leeway: Int = 100)

    /// A single-fire `DispatchWorkItem` timer.
    case oneShot(timeInterval: TimeInterval = 1.0 / 30.0,
                 qos: DispatchQoS = .default)

    /// A `DispatchSourceTimer` that fires repeatedly. Leeway is in milliseconds.
    case repeating(timeInterval: TimeInterval = 1.0 / 30.0,
                   qos: DispatchQoS = .default,
                   leeway: Int = 100)
}
