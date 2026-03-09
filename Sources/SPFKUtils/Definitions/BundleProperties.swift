// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

public struct BundleProperties: Sendable {
    public static let shared = BundleProperties()

    public let applicationVersion = ApplicationVersion()

    public init() {}

    public var appVersion: String? {
        guard let string = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return nil
        }
        return string + " \(Log.buildConfig)"
    }

    public var appName: String? = Bundle.main.infoDictionary?["CFBundleName"] as? String
    public var appVersionBuild: String? = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    public var appCopyright: String? = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String
    public var appCopyrightShort: String? = Bundle.main.infoDictionary?["ShortCopyright"] as? String

    public var fullApplicationVersion: String? {
        guard let versionBuildNumber,
              let appName else { return nil }
        return "\(appName) \(versionBuildNumber)"
    }

    public var versionBuildNumber: String? {
        guard let appVersion,
              let appVersionBuild else { return nil }
        return "\(appVersion) (Build \(appVersionBuild))"
    }

    public var appModificationDate: Date? {
        let infoPath = Bundle.main.bundleURL.path
        guard let infoAttr = try? FileManager.default.attributesOfItem(atPath: infoPath),
              let infoDate = infoAttr[.modificationDate] as? Date else { return nil }

        return infoDate
    }

    public var appVersionAndCopyright: String {
        var info = ""

        if let fullApplicationVersion {
            info += fullApplicationVersion + "\n"
        }

        if let appModificationDate {
            let builtOnDate = "Built on \(appModificationDate.onlyDateString)"
            info += "\(builtOnDate)\n"
        }

        if let appCopyright {
            info += "\(appCopyright)\n"
        }

        return info
    }

    // String for the About / Splash Window
    public var systemDescription: String {
        appVersionAndCopyright +
            "\n" +
            HardwareInfo.description
    }
}

extension BundleProperties {
    /// Return this application's default Caches directory based on the `bundleIdentifier`.
    /// IE: /Users/[USERNAME]/Library/Caches/[BUNDLE ID]
    ///
    /// or if it is sandboxed:
    /// /Users/[USERNAME]/Library/Containers/[BUNDLE ID]/Data/Library/Caches/[BUNDLE ID]
    ///
    /// This directory doesn't exist automatically and needs to be created.
    public static var cachesDirectory: URL? {
        guard let id = Bundle.main.bundleIdentifier,
              let cachesDirectory = FileManager.default.urls(
                  for: .cachesDirectory,
                  in: .userDomainMask
              ).first
        else {
            return nil
        }

        return cachesDirectory.appendingPathComponent(id)
    }

    public static var documentsDirectory: URL? {
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first
    }

    public static var applicationSupportDirectory: URL? {
        FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first
    }

    public static let appFolder: URL = Bundle.main.bundleURL.deletingLastPathComponent()
}

extension BundleProperties {
    /**
     Given a version number MAJOR.MINOR.PATCH, increment the:
     MAJOR version when you make incompatible API changes
     MINOR version when you add functionality in a backward compatible manner
     PATCH version when you make backward compatible bug fixes
     */
    public struct ApplicationVersion: Sendable {
        public private(set) var major: Int = 0
        public private(set) var minor: Int = 0
        public private(set) var patch: Int = 0
        public private(set) var build: Int = 0

        public init() {
            guard let shortVersion = Bundle.main.infoDictionaryString(key: "CFBundleShortVersionString") else { return }

            let parts = shortVersion
                .components(separatedBy: ".")
                .map { Int($0) ?? 0 }

            if parts.count >= 3 {
                major = parts[0]
                minor = parts[1]
                patch = parts[2]
            }

            if let value = Bundle.main.infoDictionaryString(key: "CFBundleVersion") {
                build = Int(value) ?? 0
            }
        }
    }
}
