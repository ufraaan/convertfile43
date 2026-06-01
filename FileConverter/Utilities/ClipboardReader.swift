import Foundation
import AppKit

enum ClipboardReader {
    static func readFileURLs() -> [URL] {
        let pasteboard = NSPasteboard.general

        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
            return urls
        }

        if let strings = pasteboard.readObjects(forClasses: [NSString.self], options: nil) as? [String] {
            return strings.compactMap { string in
                let path = string.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !path.isEmpty else { return nil }
                let url = URL(fileURLWithPath: path)
                guard FileManager.default.fileExists(atPath: url.path) else { return nil }
                return url
            }
        }

        return []
    }
}
