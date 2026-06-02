import AppKit

@MainActor
final class MenuBarManager: NSObject, NSMenuDelegate {
    private var settings: AppSettings?
    private var orchestrator: ConversionOrchestrator?
    private var statusItem: NSStatusItem?

    func setup(settings: AppSettings, orchestrator: ConversionOrchestrator) {
        self.settings = settings
        self.orchestrator = orchestrator

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let image = NSImage(systemSymbolName: "rectangle.2.swap", accessibilityDescription: "convertfile43") {
            image.isTemplate = true
            item.button?.image = image
        }
        item.menu = makeMenu()
        statusItem = item

        startObservingProgress()
    }

    private func startObservingProgress() {
        guard let orchestrator else { return }

        withObservationTracking {
            _ = orchestrator.jobs
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.updateStatusItemTitle()
                self?.startObservingProgress()
            }
        }
    }

    private func updateStatusItemTitle() {
        guard let orchestrator, let button = statusItem?.button else { return }
        if let running = orchestrator.jobs.first(where: { $0.state == .running }) {
            let pct = Int(running.progress.rounded())
            button.title = "\(pct)%"
        } else {
            button.title = ""
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        LoggerService.debug("Menu opening", component: "MenuBarManager")
        populate(menu)
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        populate(menu)
        return menu
    }

    private func populate(_ menu: NSMenu) {
        menu.removeAllItems()
        let selection = ClipboardSelection(urls: ClipboardReader.readFileURLs())

        if let orchestrator, orchestrator.isProcessing {
            let item = NSMenuItem(title: "Converting...", action: nil, keyEquivalent: "")
            item.image = NSImage(systemSymbolName: "arrow.triangle.2.circlepath", accessibilityDescription: nil)
            menu.addItem(item)
            menu.addItem(.separator())
        }

        addClipboardStatus(to: menu, selection: selection)
        addPresetMenus(to: menu, selection: selection)
        menu.addItem(.separator())

        if let orchestrator, !orchestrator.jobs.isEmpty {
            addRecentJobs(to: menu, jobs: Array(orchestrator.jobs.suffix(5).reversed()))
            menu.addItem(.separator())
        }

        addSettingsMenus(to: menu)
        menu.addItem(.separator())

        let clearItem = NSMenuItem(title: "Clear Finished Conversions", action: #selector(clearFinishedConversions), keyEquivalent: "")
        clearItem.target = self
        clearItem.isEnabled = hasFinishedJobs
        menu.addItem(clearItem)

        addLogsMenu(to: menu)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit convertfile43", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func addSettingsMenus(to menu: NSMenu) {
        let quickSettingsItem = NSMenuItem(title: "Quick Settings", action: nil, keyEquivalent: "")
        quickSettingsItem.image = NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: nil)

        let submenu = NSMenu(title: "Quick Settings")

        let revealItem = NSMenuItem(
            title: "Reveal in Finder on Complete",
            action: #selector(toggleRevealInFinder),
            keyEquivalent: ""
        )
        revealItem.target = self
        revealItem.state = settings?.revealInFinderOnComplete == true ? .on : .off
        submenu.addItem(revealItem)

        let soundItem = NSMenuItem(
            title: "Play Sound on Complete",
            action: #selector(togglePlaySound),
            keyEquivalent: ""
        )
        soundItem.target = self
        soundItem.state = settings?.playSoundOnComplete == true ? .on : .off
        submenu.addItem(soundItem)

        submenu.addItem(.separator())

        let parallelItem = NSMenuItem(title: "Max Parallel Jobs", action: nil, keyEquivalent: "")
        let parallelSubmenu = NSMenu(title: "Max Parallel Jobs")
        for count in 1...8 {
            let item = ParallelJobsMenuItem(count: count)
            item.target = self
            item.action = #selector(setMaxParallelJobs(_:))
            item.state = settings?.maxParallelJobs == count ? .on : .off
            parallelSubmenu.addItem(item)
        }
        parallelItem.submenu = parallelSubmenu
        submenu.addItem(parallelItem)

        quickSettingsItem.submenu = submenu
        menu.addItem(quickSettingsItem)
    }

    private func addClipboardStatus(to menu: NSMenu, selection: ClipboardSelection) {
        let item = NSMenuItem(title: selection.statusTitle, action: nil, keyEquivalent: "")
        item.image = NSImage(systemSymbolName: selection.statusSymbolName, accessibilityDescription: nil)
        item.isEnabled = false
        menu.addItem(item)
        menu.addItem(.separator())
    }

    private func addPresetMenus(to menu: NSMenu, selection: ClipboardSelection) {
        for category in OutputType.Category.allCases {
            let presets = presets(for: category)
            guard !presets.isEmpty else { continue }

            let item = NSMenuItem(title: category.menuTitle, action: nil, keyEquivalent: "")
            item.image = NSImage(systemSymbolName: category.symbolName, accessibilityDescription: nil)

            let submenu = NSMenu(title: category.menuTitle)
            var hasEnabledPreset = false
            for preset in presets {
                let presetItem = PresetMenuItem(preset: preset)
                presetItem.target = self
                presetItem.action = #selector(convertFromClipboard(_:))
                presetItem.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: nil)
                presetItem.isEnabled = selection.canConvertAllFiles(with: preset)
                presetItem.toolTip = selection.tooltip(for: preset)
                hasEnabledPreset = hasEnabledPreset || presetItem.isEnabled
                submenu.addItem(presetItem)
            }

            item.submenu = submenu
            item.isEnabled = hasEnabledPreset
            menu.addItem(item)
        }
    }

    private func addRecentJobs(to menu: NSMenu, jobs: [ConversionJob]) {
        let heading = NSMenuItem(title: "Recent Conversions", action: nil, keyEquivalent: "")
        heading.image = NSImage(systemSymbolName: "clock.arrow.circlepath", accessibilityDescription: nil)
        menu.addItem(heading)

        for job in jobs {
            let item = NSMenuItem(title: job.menuTitle, action: nil, keyEquivalent: "")
            item.image = NSImage(systemSymbolName: job.state.symbolName, accessibilityDescription: nil)
            item.toolTip = job.outputFileName
            menu.addItem(item)
        }
    }

    private var hasFinishedJobs: Bool {
        orchestrator?.jobs.contains { job in
            job.state == .completed || job.state == .failed || job.state == .cancelled
        } ?? false
    }

    private func presets(for category: OutputType.Category) -> [ConversionPreset] {
        settings?.presets.filter { $0.outputType.category == category } ?? []
    }

    @objc private func convertFromClipboard(_ sender: NSMenuItem) {
        guard let sender = sender as? PresetMenuItem else {
            LoggerService.error("convertFromClipboard called with non-PresetMenuItem", component: "MenuBarManager")
            return
        }
        let urls = ClipboardReader.readFileURLs()
        let selection = ClipboardSelection(urls: urls)
        guard selection.canConvertAllFiles(with: sender.preset), let orchestrator else {
            LoggerService.warning("Cannot convert: preset '\(sender.preset.name)' not compatible with clipboard files",
                component: "MenuBarManager")
            NSSound.beep()
            return
        }

        LoggerService.info("Converting \(urls.count) file(s) with preset '\(sender.preset.name)'",
            component: "MenuBarManager")
        for url in urls {
            orchestrator.addJob(inputURL: url, preset: sender.preset)
        }
    }

    @objc private func toggleRevealInFinder() {
        guard let settings else { return }
        settings.revealInFinderOnComplete.toggle()
        settings.saveGeneralPreferences()
    }

    @objc private func togglePlaySound() {
        guard let settings else { return }
        settings.playSoundOnComplete.toggle()
        settings.saveGeneralPreferences()
    }

    @objc private func setMaxParallelJobs(_ sender: NSMenuItem) {
        guard let sender = sender as? ParallelJobsMenuItem else { return }
        settings?.maxParallelJobs = sender.count
        settings?.saveGeneralPreferences()
    }

    private func addLogsMenu(to menu: NSMenu) {
        let logsItem = NSMenuItem(title: "Show Logs", action: nil, keyEquivalent: "")
        logsItem.image = NSImage(systemSymbolName: "doc.text.magnifyingglass", accessibilityDescription: nil)

        let submenu = NSMenu(title: "Show Logs")

        let openFileItem = NSMenuItem(title: "Open Log File", action: #selector(openLogFile), keyEquivalent: "")
        openFileItem.target = self
        openFileItem.image = NSImage(systemSymbolName: "doc.text", accessibilityDescription: nil)
        submenu.addItem(openFileItem)

        let openFolderItem = NSMenuItem(title: "Open Logs Folder", action: #selector(openLogFolder), keyEquivalent: "")
        openFolderItem.target = self
        openFolderItem.image = NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
        submenu.addItem(openFolderItem)

        logsItem.submenu = submenu
        menu.addItem(logsItem)
    }

    @objc private func openLogFile() {
        LoggerService.openLogFile()
    }

    @objc private func openLogFolder() {
        LoggerService.openLogDirectory()
    }

    @objc private func clearFinishedConversions() {
        orchestrator?.clearCompleted()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

private final class PresetMenuItem: NSMenuItem {
    let preset: ConversionPreset

    init(preset: ConversionPreset) {
        self.preset = preset
        super.init(title: preset.name, action: nil, keyEquivalent: "")
        toolTip = "Convert copied Finder files to \(preset.outputType.displayName)"
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class ParallelJobsMenuItem: NSMenuItem {
    let count: Int

    init(count: Int) {
        self.count = count
        super.init(title: "\(count)", action: nil, keyEquivalent: "")
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct ClipboardSelection {
    let urls: [URL]

    var statusTitle: String {
        if urls.isEmpty {
            return "No copied Finder files"
        }

        if urls.count == 1 {
            return "1 copied file"
        }

        return "\(urls.count) copied files"
    }

    var statusSymbolName: String {
        urls.isEmpty ? "doc.on.clipboard" : "doc.on.clipboard.fill"
    }

    func canConvertAllFiles(with preset: ConversionPreset) -> Bool {
        guard !urls.isEmpty else { return false }
        return unsupportedURLs(for: preset).isEmpty
    }

    func tooltip(for preset: ConversionPreset) -> String {
        guard !urls.isEmpty else {
            return "Copy files in Finder first"
        }

        let unsupported = unsupportedURLs(for: preset)
        guard !unsupported.isEmpty else {
            return "Convert \(urls.count == 1 ? "file" : "\(urls.count) files") to \(preset.outputType.displayName)"
        }

        let names = unsupported
            .prefix(3)
            .map(\.lastPathComponent)
            .joined(separator: ", ")
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

private extension OutputType.Category {
    static var allCases: [OutputType.Category] {
        [.audio, .video, .image, .document]
    }

    var menuTitle: String {
        switch self {
        case .audio: return "Convert Audio"
        case .video: return "Convert Video"
        case .image: return "Convert Images"
        case .document: return "Convert Documents"
        }
    }

    var symbolName: String {
        switch self {
        case .audio: return "waveform"
        case .video: return "film"
        case .image: return "photo"
        case .document: return "doc.richtext"
        }
    }
}

private extension ConversionJob {
    var menuTitle: String {
        let truncated = fileName.truncatedWithExtension(maxLength: 36)
        switch state {
        case .queued:
            return "\(truncated) - Queued"
        case .running:
            return "\(truncated) - \(Int(progress))%"
        case .completed:
            return "\(truncated) - Done"
        case .failed:
            if let error = errorMessage, !error.isEmpty {
                let shortError = error.prefix(40)
                return "\(truncated) - Failed: \(shortError)"
            }
            return "\(truncated) - Failed"
        case .cancelled:
            return "\(truncated) - Cancelled"
        }
    }
}

private extension String {
    func truncatedWithExtension(maxLength: Int) -> String {
        guard count > maxLength else { return self }
        let ext = (self as NSString).pathExtension
        let base = (self as NSString).deletingPathExtension
        let extDot = ext.isEmpty ? "" : ".\(ext)"
        let available = maxLength - extDot.count - 3
        guard available > 0 else { return "..." + extDot }
        return base.prefix(available) + "..." + extDot
    }
}

private extension ConversionState {
    var symbolName: String {
        switch self {
        case .queued: return "hourglass"
        case .running: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle"
        case .failed: return "xmark.circle"
        case .cancelled: return "minus.circle"
        }
    }
}
