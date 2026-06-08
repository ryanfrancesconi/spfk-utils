#if os(macOS)

// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKBase

/// Legacy Timer based on screen refresh rate
@available(macOS, deprecated: 14.0, message: "Use DisplayLinkTimer")
public class LegacyDisplayLinkTimer: TimerModel {
    public var timeInterval: TimeInterval {
        displayLink?.timeInterval ?? 0
    }

    public var eventHandler: (() -> Void)? {
        didSet {
            displayLink?.callback = eventHandler
        }
    }

    public private(set) var state: TimerState = .suspended

    private var displayLink: DisplayLink?

    // global(qos: .default)
    public init(onQueue queue: DispatchQueue = .main) {
        do {
            Log.debug("Creating on", queue)
            displayLink = try DisplayLink(onQueue: queue)
        } catch {
            Log.error(error)
        }
    }

    public func resume() {
        guard state == .suspended else { return }
        displayLink?.start()
        state = .resumed
    }

    public func suspend() {
        guard state == .resumed else { return }
        displayLink?.suspend()
        state = .suspended
    }

    deinit {
        Log.debug("- { \(self) }")
    }

    public func dispose() {
        displayLink?.cancel()
        eventHandler = nil
        displayLink = nil
    }
}

#endif
