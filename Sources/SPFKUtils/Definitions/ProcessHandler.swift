// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import Foundation
    import SPFKBase

    public class ProcessHandler {
        public var process = Process()
        public let outputPipe = Pipe()
        public let errorPipe = Pipe()

        public var qos: DispatchQoS.QoSClass

        public init(url: URL, args: [String], qos: DispatchQoS.QoSClass = .default) {
            self.qos = qos

            process.executableURL = url
            process.arguments = args
            process.qualityOfService = qos.qualityOfService
            process.standardOutput = outputPipe
            process.standardError = errorPipe
        }

        public func run() throws -> String {
            var output = ""

            try process.run()

            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            if let string = String(data: data, encoding: .utf8) {
                output += string + "\n"
            }

            let error = errorPipe.fileHandleForReading.readDataToEndOfFile()
            if let string = String(data: error, encoding: .utf8) {
                output += string + "\n"
            }
            process.waitUntilExit()

            return output
        }

        public func cancel() {
            guard process.isRunning else {
                Log.error("Process isn't running")
                return
            }

            process.terminate()
        }
    }

#endif
