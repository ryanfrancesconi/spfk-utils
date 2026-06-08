// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// A repeating timer backed by `NSTimer`, scheduled on the main run loop in `.common` mode.
public class BasicTimer: TimerModel {
    public var timerType: TimerType {
        .basic(timeInterval: timeInterval, leeway: leeway)
    }

    public var eventHandler: (() -> Void)?

    public private(set) var state: TimerState = .suspended

    public private(set) var timeInterval: TimeInterval = 1

    /// Leeway in milliseconds
    public private(set) var leeway: Int = 100

    public private(set) var timer: Timer?

    /// Leeway in milliseconds
    public init(timeInterval: TimeInterval, leeway: Int = 100, eventHandler: (() -> Void)? = nil) {
        self.timeInterval = timeInterval
        self.leeway = leeway
        self.eventHandler = eventHandler
    }

    public func resume() {
        guard state == .suspended else {
            return
        }

        state = .resumed

        if timer != nil {
            timer?.invalidate()
        }

        timer = Timer(
            timeInterval: timeInterval,
            target: self,
            selector: #selector(handleEvent),
            userInfo: nil,
            repeats: true
        )

        timer?.tolerance = Double(leeway) / 1000

        if let timer {
            RunLoop.main.add(
                timer,
                forMode: .common
            )
        }
    }

    public func suspend() {
        guard state == .resumed else {
            // Log.error("Timer is already suspended")
            return
        }
        state = .suspended
        timer?.invalidate()
        timer = nil
    }

    @objc
    public func handleEvent() {
        eventHandler?()
    }

    public func dispose() {
        timer?.invalidate()
        timer = nil
        eventHandler = nil
    }

    deinit {
    }
}
