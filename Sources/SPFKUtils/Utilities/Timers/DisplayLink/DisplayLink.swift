#if os(macOS)

    // Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

    import CoreVideo
    import SPFKBase

    /// Analog to the CADisplayLink in iOS.
    /// Pre macOS 14 class, will use the main display
    @available(macOS, deprecated: 14.0, message: "Use DisplayLinkTimer")
    public class DisplayLink {
        public let displaylink: CVDisplayLink
        let source: DispatchSourceUserDataAdd

        public var callback: (() -> Void)?

        public private(set) var running: Bool = false

        public var timeInterval: TimeInterval {
            let cvTime = CVDisplayLinkGetNominalOutputVideoRefreshPeriod(displaylink)
            return cvTime.timeValue.double / cvTime.timeScale.double
        }

        /**
         Creates a new DisplayLink that gets executed on the given queue

         - Parameters:
         - queue: Queue which will receive the callback calls
         */
        public init(onQueue queue: DispatchQueue = .main) throws {
            // Source
            source = DispatchSource.makeUserDataAddSource(queue: queue)

            // Timer
            var timerRef: CVDisplayLink?

            // Create timer
            var err = CVDisplayLinkCreateWithActiveCGDisplays(&timerRef)

            guard let timerRef else {
                throw NSError(description: "Failed to create timer")
            }

            // GROSS: Set Output
            err = CVDisplayLinkSetOutputCallback(
                timerRef,
                { (_: CVDisplayLink,
                   _: UnsafePointer<CVTimeStamp>,
                   _: UnsafePointer<CVTimeStamp>,
                   _: CVOptionFlags,
                   _: UnsafeMutablePointer<CVOptionFlags>,
                   sourceUnsafeRaw: UnsafeMutableRawPointer?) -> CVReturn in
                        // Un-opaque the source
                        if let sourceUnsafeRaw {
                            // Update the value of the source, thus, triggering a handle call on the timer
                            let sourceUnmanaged = Unmanaged<DispatchSourceUserDataAdd>.fromOpaque(sourceUnsafeRaw)
                            sourceUnmanaged.takeUnretainedValue().add(data: 1)
                        }
                        return kCVReturnSuccess

                },
                Unmanaged.passUnretained(source).toOpaque()
            )

            guard err == kCVReturnSuccess else {
                throw NSError(description: "Failed to create timer with active display")
            }

            // Connect to MAIN display
            err = CVDisplayLinkSetCurrentCGDisplay(timerRef, CGMainDisplayID())

            guard err == kCVReturnSuccess else {
                throw NSError(description: "Failed to connect to display")
            }

            displaylink = timerRef

            // Timer setup
            source.setEventHandler { [weak self] in
                self?.callback?()
            }
        }

        /// Starts the timer
        public func start() {
            guard !running else {
                return
            }

            let status = CVDisplayLinkStart(displaylink)

            guard status == kCVReturnSuccess else {
                Log.error("Failed to start timer")
                return
            }

            source.resume()
            running = true
        }

        /// Suspends the timer, can be restarted afterwards
        public func suspend() {
            guard running else {
                return
            }

            let status = CVDisplayLinkStop(displaylink)

            guard status == kCVReturnSuccess else {
                Log.error("Failed to stop timer")
                return
            }

            source.suspend()
            running = false
        }

        public func cancel() {
            guard running else {
                return
            }

            let status = CVDisplayLinkStop(displaylink)

            guard status == kCVReturnSuccess else {
                Log.error("Failed to stop timer")
                return
            }

            source.cancel()
            running = false
        }

        deinit {
            Log.debug("- { \(self) }")

            // If the timer is suspended, calling cancel without resuming
            // triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
            if !running {
                source.resume()
            }

            CVDisplayLinkStop(displaylink)
            source.cancel()
            callback = nil
        }
    }

#endif
