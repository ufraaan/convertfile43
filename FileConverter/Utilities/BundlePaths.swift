import Foundation

enum BundlePaths {
    static var ffmpeg: String {
        findBinary("ffmpeg")
    }

    static var imagemagick: String {
        findBinary("magick")
    }

    static var ghostscript: String {
        findBinary("gs")
    }

    private static func findBinary(_ name: String) -> String {
        if let bundled = Bundle.main.path(forResource: name, ofType: nil) {
            return bundled
        }
        let brewPaths = [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
        ]
        for path in brewPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
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
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                ?? name
        }
        return name
    }
}
