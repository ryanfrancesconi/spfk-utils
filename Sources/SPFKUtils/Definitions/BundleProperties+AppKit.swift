// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit

    extension BundleProperties {
        @MainActor
        public static func relaunch(afterDelay seconds: TimeInterval = 0.5) -> Never {
            let task = Process()
            task.launchPath = "/bin/sh"
            task.arguments = ["-c", "sleep \(seconds); open \"\(Bundle.main.bundlePath)\""]
            task.launch()

            NSApp.terminate(self)
            exit(0)
        }
    }
#endif // canImport(AppKit)
