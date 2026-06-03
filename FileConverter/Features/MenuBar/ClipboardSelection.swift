import Foundation

struct ClipboardSelection {
    let urls: [URL]

    var statusTitle: String {
        if urls.isEmpty { return "No copied Finder files" }
        if urls.count == 1 { return "1 copied file" }
        return "\(urls.count) copied files"
    }

    var statusSymbolName: String {
        urls.isEmpty ? "doc.on.clipboard" : "doc.on.clipboard.fill"
    }

    func canConvertAllFiles(with preset: ConversionPreset) -> Bool {
        guard !urls.isEmpty else { return false }
        return unsupportedURLs(for: preset).isEmpty
    }

    func canConvertAnyFile(with preset: ConversionPreset) -> Bool {
        guard !urls.isEmpty else { return false }
        return unsupportedURLs(for: preset).count < urls.count
    }

    func tooltip(for preset: ConversionPreset) -> String {
        guard !urls.isEmpty else { return "Copy files in Finder first (⌘C)" }
        let unsupported = unsupportedURLs(for: preset)
        guard !unsupported.isEmpty else {
            return "Convert \(urls.count == 1 ? "file" : "\(urls.count) files") to \(preset.outputType.displayName)"
        }
        let names = unsupported.prefix(3).map(\.lastPathComponent).joined(separator: ", ")
        let suffix = unsupported.count > 3 ? ", and \(unsupported.count - 3) more" : ""
        return "Not available for \(names)\(suffix)"
    }

    private func unsupportedURLs(for preset: ConversionPreset) -> [URL] {
        let supportedExtensions = Set(preset.inputExtensions.map { $0.lowercased() })
        return urls.filter { url in
            let fileExtension = url.pathExtension.lowercased()
            return fileExtension.isEmpty || !supportedExtensions.contains(fileExtension)
        }
    }
}
