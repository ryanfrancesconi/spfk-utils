// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Darwin
import Foundation
import IOKit

/// Only accounting for macOS
public enum HardwareInfo {
    public enum ChipType: String, Sendable {
        case x86_64
        case arm64

        public var description: String {
            switch self {
            case .arm64: "Apple Silicon"
            case .x86_64: "Intel"
            }
        }
    }

    /// For late-model Intel Macs, this returns x86_64. For Apple Silicon, it returns arm64.
    public static let chip: ChipType? = {
        var sysinfo = utsname()

        guard EXIT_SUCCESS == uname(&sysinfo) else { return nil }

        let data = Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN))

        guard let identifier = String(bytes: data, encoding: .ascii) else { return nil }

        let rawValue = identifier.trimmingCharacters(in: .controlCharacters)

        return ChipType(rawValue: rawValue)
    }()

    private static func sysctl(name: String) -> String? {
        var size = 0
        guard noErr == sysctlbyname(name, nil, &size, nil, 0) else {
            return nil
        }

        var machine = [CChar](repeating: 0, count: size)

        guard noErr == sysctlbyname(name, &machine, &size, nil, 0) else {
            return nil
        }

        let string = String(utf8String: machine)

        return string
    }

    // MARK: - conveniences

    /// Apple M1 Max, etc
    public static let chipname: String? = sysctl(name: "machdep.cpu.brand_string")

    public static let memory: String = {
        let memory = ProcessInfo.processInfo.physicalMemory / ByteCount.gigabyte.rawValue
        return "\(memory) GB memory"
    }()

    public static let description: String = {
        let os = ProcessInfo.processInfo.operatingSystemVersionString

        var info = "macOS \(os)\n"
        info += "\(chipname ?? "?"), "
        info += "\(ProcessInfo.processInfo.activeProcessorCount) cores. "
        info += "\(memory)."

        return info
    }()

    public static let hardwareUUID: String? = {
        let platformExpert = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )

        defer { IOObjectRelease(platformExpert) }

        return IORegistryEntryCreateCFProperty(
            platformExpert,
            "IOPlatformUUID" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? String
    }()
}
