import Foundation
import AppKit

enum ClipboardReader {
    static func readFileURLs() -> [URL] {
        let pasteboard = NSPasteboard.general
        let changeCount = pasteboard.changeCount

        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
            LoggerService.info("Read \(urls.count) file(s) from pasteboard (NSURL) — changeCount: \(changeCount)", component: "ClipboardReader")
            for url in urls {
                LoggerService.debug("  -> \(url.path)", component: "ClipboardReader")
            }
            return urls
        }

        if let strings = pasteboard.readObjects(forClasses: [NSString.self], options: nil) as? [String] {
            let urls = strings.compactMap { string -> URL? in
                let path = string.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !path.isEmpty else { return nil }
                let url = URL(fileURLWithPath: path)
                guard FileManager.default.fileExists(atPath: url.path) else {
                    LoggerService.debug("Ignored non-existent path from pasteboard: \(path)", component: "ClipboardReader")
                    return nil
                }
                return url
            }
            if urls.isEmpty {
                LoggerService.info("No valid file URLs found on pasteboard (changeCount: \(changeCount))", component: "ClipboardReader")
            } else {
                LoggerService.info("Read \(urls.count) file(s) from pasteboard (NSString fallback) — changeCount: \(changeCount)", component: "ClipboardReader")
            }
            return urls
        }

        LoggerService.info("Pasteboard empty — no NSURL or NSString objects found (changeCount: \(changeCount))", component: "ClipboardReader")
        return []
    }
}
