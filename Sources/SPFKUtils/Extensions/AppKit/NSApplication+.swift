// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import AppKit

    extension NSApplication {
        /// Relaunch the current application.
        /// PID polling (kill -0) so the relaunch fires immediately when the process exits.
        ///
        /// - Returns: Never
        @MainActor
        public static func relaunch() -> Never {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/sh")
            let pid = ProcessInfo.processInfo.processIdentifier
            task.arguments = ["-c", "while kill -0 $PID 2>/dev/null; do sleep 0.1; done; open \"$APP_PATH\""]
            task.environment = ["PID": "\(pid)", "APP_PATH": Bundle.main.bundlePath]
            try? task.run()

            NSApp.terminate(nil)
            exit(0)
        }
    }
#endif
