// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// RepeatingTimer mimics the API of DispatchSourceTimer but in a way that prevents
/// crashes that occur from calling resume multiple times on a timer that is
/// already resumed (noted by https://github.com/SiftScience/sift-ios/issues/52
public class RepeatingTimer: TimerModel {
    public var timerType: TimerType {
        .repeating(timeInterval: timeInterval, qos: queue.qos, leeway: leeway)
    }

    public var eventHandler: (() -> Void)? {
        didSet {
            timer.setEventHandler(handler: eventHandler)
        }
    }

    public private(set) var state: TimerState = .suspended

    public private(set) var timeInterval: TimeInterval = 1

    /// leeway in milliseconds
    public private(set) var leeway: Int = 50

    private let queue: DispatchQueue

    public init(timeInterval: TimeInterval,
                qos: DispatchQoS = .default,
                leeway: Int = 100,
                eventHandler: (() -> Void)? = nil)
    {
        self.timeInterval = timeInterval
        self.leeway = leeway

        queue = DispatchQueue(
            label: "com.spongefork.SPFKTime.RepeatingTimer",
            qos: qos
        )

        self.eventHandler = eventHandler
    }

    private lazy var timer: DispatchSourceTimer = {
        let source = DispatchSource.makeTimerSource(
            flags: DispatchSource.TimerFlags(),
            queue: queue
        )

        source.schedule(
            deadline: .now() + timeInterval,
            repeating: timeInterval,
            leeway: .milliseconds(leeway)
        )

        return source
    }()

    public func resume() {
        guard state == .suspended else {
            // Log.error("Timer is already resumed")
            return
        }
        state = .resumed
        timer.resume()
    }

    public func suspend() {
        guard state == .resumed else {
            // Log.error("Timer is already suspended")
            return
        }
        state = .suspended
        timer.suspend()
    }

    public func dispose() {
        timer.setEventHandler {}
        timer.cancel()
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
         */
        resume()
        eventHandler = nil
    }
}
