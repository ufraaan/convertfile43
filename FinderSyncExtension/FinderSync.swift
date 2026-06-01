import FinderSync
import Foundation

@objc(FinderSyncExtension)
final class FinderSyncExtension: FIFinderSync {
    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    override var toolbarItemName: String {
        "File Converter"
    }

    override var toolbarItemToolTip: String {
        "Convert selected files with File Converter"
    }

    override var toolbarItemImage: NSImage {
        NSImage(systemSymbolName: "arrow.left.arrow.right.square", accessibilityDescription: nil)
            ?? NSImage()
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        switch menuKind {
        case .contextualMenuForItems, .toolbarItemMenu:
            let menu = NSMenu(title: "File Converter")

            let presets = loadPresets()
            guard !presets.isEmpty else {
                let item = NSMenuItem(title: "No presets available", action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
                return menu
            }

            for preset in presets {
                let item = NSMenuItem(
                    title: preset.name,
                    action: #selector(convertWithPreset(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                let icon = NSImage(systemSymbolName: iconForOutputType(preset.outputType), accessibilityDescription: nil)
                item.image = icon
                menu.addItem(item)
            }

            menu.addItem(NSMenuItem.separator())

            let openAppItem = NSMenuItem(
                title: "Open File Converter...",
                action: #selector(openMainApp(_:)),
                keyEquivalent: ""
            )
            openAppItem.target = self
            menu.addItem(openAppItem)

            return menu

        default:
            return nil
        }
    }

    @objc private func convertWithPreset(_ sender: NSMenuItem) {
        let presetName = sender.title
        let controller = FIFinderSyncController.default()
        let urls = controller.selectedItemURLs() ?? []

        guard !urls.isEmpty else { return }

        let request = FinderConversionRequest(
            files: urls,
            presetName: presetName,
            timestamp: Date()
        )

        guard let data = try? JSONEncoder().encode(request) else { return }

        let requestsDir = appGroupRequestsDirectory()
        try? FileManager.default.createDirectory(at: requestsDir, withIntermediateDirectories: true)

        let filename = "request_\(UUID().uuidString).json"
        let fileURL = requestsDir.appendingPathComponent(filename)
        try? data.write(to: fileURL)

        activateMainApp()
    }

    @objc private func openMainApp(_ sender: Any?) {
        activateMainApp()
    }

    private func activateMainApp() {
        guard let appURL = containingAppURL() else { return }
        NSWorkspace.shared.openApplication(
            at: appURL,
            configuration: NSWorkspace.OpenConfiguration(),
            completionHandler: nil
        )
    }

    private func iconForOutputType(_ type: String) -> String {
        switch type {
        case "mp3", "aac", "flac", "ogg", "wav": return "music.note"
        case "mp4", "mkv", "avi", "webm", "ogv": return "film"
        case "jpg", "png", "webp", "gif", "ico": return "photo"
        case "pdf": return "doc.text"
        default: return "doc"
        }
    }

    private func containingAppURL() -> URL? {
        Bundle.main.bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}

extension FinderSyncExtension {
    private func loadPresets() -> [PresetMenuItem] {
        let appGroupDir = appGroupDirectory()
        let presetsFile = appGroupDir.appendingPathComponent("presets.json")

        if let data = try? Data(contentsOf: presetsFile),
           let presets = try? JSONDecoder().decode([PresetMenuItem].self, from: data) {
            return presets
        }

        return defaultPresets()
    }

    private func appGroupDirectory() -> URL {
        let appID = Bundle.main.bundleIdentifier?
            .replacingOccurrences(of: ".FinderSyncExtension", with: ".app") ?? "com.fileconverter.app"
        let teamPrefix = "com.fileconverter"
        let groupID = "\(teamPrefix).app"

        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)
            ?? FileManager.default.temporaryDirectory
    }

    private func appGroupRequestsDirectory() -> URL {
        appGroupDirectory().appendingPathComponent("Requests")
    }

    private func defaultPresets() -> [PresetMenuItem] {
        [
            PresetMenuItem(name: "MP3 320kbps", outputType: "mp3"),
            PresetMenuItem(name: "AAC 256kbps", outputType: "aac"),
            PresetMenuItem(name: "MP4 1080p", outputType: "mp4"),
            PresetMenuItem(name: "MP4 720p", outputType: "mp4"),
            PresetMenuItem(name: "JPEG High Quality", outputType: "jpg"),
        ]
    }
}

struct PresetMenuItem: Codable {
    let name: String
    let outputType: String
}
