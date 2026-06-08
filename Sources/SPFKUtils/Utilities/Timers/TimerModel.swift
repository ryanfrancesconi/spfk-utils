// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// Common interface for all timer implementations (basic, one-shot, repeating, display-link).
///
/// Timers start in the ``TimerState/suspended`` state. Call ``resume()`` to start
/// firing, ``suspend()`` to pause, and ``dispose()`` to permanently release resources.
public protocol TimerModel: AnyObject {
    /// Closure called on each timer tick.
    var eventHandler: (() -> Void)? { get set }

    /// The current run state of the timer.
    var state: TimerState { get }

    /// The interval between timer firings, in seconds.
    var timeInterval: TimeInterval { get }

    /// Starts or resumes the timer. No-op if already resumed.
    func resume()

    /// Pauses the timer. No-op if already suspended.
    func suspend()

    /// Permanently stops the timer and releases all resources.
    func dispose()
}

extension TimerModel {
    /// The effective frames-per-second rate derived from ``timeInterval``.
    public var fps: Double {
        1 / timeInterval
    }
}
