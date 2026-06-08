#if os(macOS)
    // Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

    import AppKit
    import Foundation
    import QuartzCore
    import SPFKBase

    /// A display-link timer backed by `CADisplayLink` (macOS 14+).
    ///
    /// Fires in sync with the screen's refresh rate for smooth UI updates.
    /// Create from an `NSView`, `NSWindow`, or `NSScreen` to bind to
    /// the appropriate display.
    @available(macOS 14, *)
    public class DisplayLinkTimer: TimerModel {
        public var eventHandler: (() -> Void)?

        /// The display's frame duration in seconds.
        public var timeInterval: TimeInterval {
            displayLink?.duration ?? 0
        }

        public private(set) var state: TimerState = .suspended

        /// The display's current refresh rate in frames per second.
        public var fps: Double {
            guard let displayLink else { return 0 }
            let delta = displayLink.targetTimestamp - displayLink.timestamp
            guard delta > 0 else { return 0 }
            return 1 / delta
        }

        /// The timestamp of the last display refresh.
        public var timestamp: CFTimeInterval {
            displayLink?.timestamp ?? 0
        }

        private var displayLink: CADisplayLink?

        @MainActor public init(on view: NSView) {
            displayLink = view.displayLink(target: self, selector: #selector(handleUpdate))
        }

        @MainActor public init(window: NSWindow) {
            displayLink = window.displayLink(target: self, selector: #selector(handleUpdate))
        }

        @MainActor public init(screen: NSScreen) {
            displayLink = screen.displayLink(target: self, selector: #selector(handleUpdate))
        }

        @objc private func handleUpdate(_ sender: CADisplayLink) {
            eventHandler?()
        }

        public func resume() {
            guard let displayLink else { return }
            guard state == .suspended else { return }

            displayLink.isPaused = false
            displayLink.add(to: .main, forMode: .common)

            state = .resumed
        }

        public func suspend() {
            guard let displayLink else { return }

            guard state == .resumed else { return }

            displayLink.isPaused = true
            displayLink.remove(from: .main, forMode: .common)

            state = .suspended
        }

        public func dispose() {
            displayLink?.invalidate()
            displayLink = nil
            eventHandler = nil
        }

        deinit {
            Log.debug("- { \(self) }")
        }
    }
#endif
