import Foundation

enum BundlePaths {
    static var ffmpeg: String {
        findBinary("ffmpeg")
    }

    private static func findBinary(_ name: String) -> String {
        if let bundled = Bundle.main.path(forResource: name, ofType: nil) {
            LoggerService.info("Found bundled binary '\(name)' at: \(bundled)", component: "BundlePaths")
            return bundled
        }
        LoggerService.debug("Binary '\(name)' not in bundle, checking system paths", component: "BundlePaths")

        let brewPaths = [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
        ]
        for path in brewPaths {
            if FileManager.default.fileExists(atPath: path) {
                LoggerService.info("Found binary '\(name)' at Homebrew path: \(path)", component: "BundlePaths")
                return path
            }
            LoggerService.debug("Binary '\(name)' not found at: \(path)", component: "BundlePaths")
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = [name]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        if task.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let found = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? name
            LoggerService.info("Found binary '\(name)' via which: \(found)", component: "BundlePaths")
            return found
        }

        LoggerService.error("Binary '\(name)' not found in bundle, Homebrew paths, or PATH. Returning bare name.", component: "BundlePaths")
        return name
    }
}
