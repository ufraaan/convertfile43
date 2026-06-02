import Foundation
import AppKit

enum LoggerService {
    enum Level: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }

    private static let appName = "com.convertfile43.app"

    private static let logDirectory: URL = {
        let paths = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
        let library = paths[0]
        let dir = library.appendingPathComponent("Logs").appendingPathComponent(appName)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private static let logFile: URL = {
        logDirectory.appendingPathComponent("conversion.log")
    }()

    private static let queue = DispatchQueue(label: "com.convertfile43.logger")
    private static let maxFileSize: UInt64 = 1024 * 1024
    private static let maxArchives = 3

    static func debug(_ message: String, component: String = #fileID) {
        log(message, level: .debug, component: component)
    }

    static func info(_ message: String, component: String = #fileID) {
        log(message, level: .info, component: component)
    }

    static func warning(_ message: String, component: String = #fileID) {
        log(message, level: .warning, component: component)
    }

    static func error(_ message: String, component: String = #fileID) {
        log(message, level: .error, component: component)
    }

    static func sessionHeader() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString

        let header = """
        === convertfile43 v\(appVersion) (build \(buildVersion)) | macOS \(osVersion) | \(Date()) ===

        """
        queue.async {
            if let data = header.data(using: .utf8) {
                if let handle = try? FileHandle(forWritingTo: logFile) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    try? handle.close()
                } else {
                    try? data.write(to: logFile)
                }
            }
        }
    }

    static func openLogFile() {
        NSWorkspace.shared.open(logFile)
    }

    static func openLogDirectory() {
        NSWorkspace.shared.open(logDirectory)
    }

    static var logFileURL: URL { logFile }
    static var logDirectoryURL: URL { logDirectory }

    private static func log(_ message: String, level: Level, component: String) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.string(from: Date())
        let line = "[\(timestamp)] [\(level.rawValue)] [\(component)] \(message)\n"

        queue.async {
            rotateIfNeeded()
            if let handle = try? FileHandle(forWritingTo: logFile) {
                handle.seekToEndOfFile()
                if let data = line.data(using: .utf8) {
                    handle.write(data)
                }
                try? handle.close()
            } else {
                try? line.data(using: .utf8)?.write(to: logFile)
            }
        }
    }

    private static func rotateIfNeeded() {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: logFile.path),
              let size = attrs[.size] as? UInt64,
              size > maxFileSize else { return }

        let oldest = logDirectory.appendingPathComponent("conversion.\(maxArchives + 1).log")
        try? FileManager.default.removeItem(at: oldest)

        for i in (1...maxArchives).reversed() {
            let src = logDirectory.appendingPathComponent("conversion.\(i).log")
            let dst = logDirectory.appendingPathComponent("conversion.\(i + 1).log")
            if FileManager.default.fileExists(atPath: src.path) {
                try? FileManager.default.moveItem(at: src, to: dst)
            }
        }

        try? FileManager.default.moveItem(at: logFile, to: logDirectory.appendingPathComponent("conversion.1.log"))
    }
}
