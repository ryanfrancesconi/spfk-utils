// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import AppKit

    extension NSApplication {
        /// Relaunch the current application.
        /// PID polling (kill -0) so the relaunch fires immediately when the process exits.
        ///
        /// - Throws: when the helper that reopens the app cannot start. The app is still running
        ///   then, so the caller decides how to tell the user.
        @MainActor
        public static func relaunch() throws -> Never {
            try launchRelaunchHelper()

            NSApp.terminate(nil)
            exit(0)
        }

        /// Starts the shell that waits for this process to exit and then opens the app again.
        static func launchRelaunchHelper(shell: URL = URL(fileURLWithPath: "/bin/sh")) throws {
            let task = Process()
            task.executableURL = shell
            let pid = ProcessInfo.processInfo.processIdentifier
            task.arguments = ["-c", "while kill -0 $PID 2>/dev/null; do sleep 0.1; done; open \"$APP_PATH\""]
            task.environment = ["PID": "\(pid)", "APP_PATH": Bundle.main.bundlePath]
            try task.run()
        }
    }
#endif
