import SwiftUI

struct MenuBarContent: View {
    let settings: AppSettings
    let orchestrator: ConversionOrchestrator
    @State private var clipboardURLs: [URL] = []
    @State private var clipboardChangeCount = -1
    @State private var menuRefreshToken = 0
    @State private var lastJobsSnapshot = ""
    @Environment(\.openSettings) private var openSettings

    private var selection: ClipboardSelection {
        ClipboardSelection(urls: clipboardURLs)
    }

    var body: some View {
        Group {
            clipboardSection

            Divider()

            convertMenusSection

            activeJobSection

            queueSection

            recentConversionsSection

            Divider()

            quickSettingsMenu

            Button {
                openSettings()
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("Settings...", systemImage: "gearshape")
            }
            .keyboardShortcut(",")

            Divider()

            Button {
                orchestrator.clearCompleted()
            } label: {
                Label("Clear Finished Conversions", systemImage: "trash")
            }
            .disabled(!hasFinishedJobs)

            logsMenu

            Divider()

            Button {
                quitApplication()
            } label: {
                Label("Quit convertfile43", systemImage: "power")
            }
            .keyboardShortcut("q")
        }
        .id(menuRefreshToken)
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            refreshClipboard()
            refreshOrchestratorSnapshot()
        }
    }

    @ViewBuilder
    private var clipboardSection: some View {
        Label(selection.statusTitle, systemImage: selection.statusSymbolName)
            .disabled(true)

        if !clipboardURLs.isEmpty {
            ForEach(clipboardURLs.prefix(5), id: \.self) { url in
                Text(url.lastPathComponent.truncatedWithExtension(maxLength: 40))
            }
            if clipboardURLs.count > 5 {
                Text("...and \(clipboardURLs.count - 5) more")
            }
        }
    }

    @ViewBuilder
    private var convertMenusSection: some View {
        ForEach(OutputType.Category.allCases, id: \.self) { category in
            let presets = settings.presets.filter { $0.outputType.category == category }
            if !presets.isEmpty {
                Menu {
                    ForEach(presets, id: \.id) { preset in
                        Button(preset.name) {
                            convert(with: preset)
                        }
                        .disabled(!selection.canConvertAllFiles(with: preset))
                        .help(selection.tooltip(for: preset))
                    }
                } label: {
                    Label(category.menuTitle, systemImage: category.symbolName)
                }
            }
        }
    }

    @ViewBuilder
    private var activeJobSection: some View {
        if let running = orchestrator.jobs.first(where: { $0.state == .running }) {
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text(running.fileName.truncatedWithExtension(maxLength: 44))
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                running.activeProgressRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 2)
            Button {
                orchestrator.cancelJob(id: running.id)
            } label: {
                Label("Cancel", systemImage: "xmark.circle")
            }
        }
    }

    @ViewBuilder
    private var queueSection: some View {
        let queued = orchestrator.jobs.filter { $0.state == .queued }
        if !queued.isEmpty {
            Divider()
            Menu {
                ForEach(queued, id: \.id) { job in
                    Label(job.menuTitle, systemImage: job.state.symbolName)
                }
            } label: {
                Label("Queue (\(queued.count))", systemImage: "hourglass")
            }
        }
    }

    @ViewBuilder
    private var recentConversionsSection: some View {
        let recent = orchestrator.jobs.filter { $0.state != .queued }
        if !recent.isEmpty {
            Divider()
            Menu {
                ForEach(recent.suffix(5).reversed(), id: \.id) { job in
                    Label(job.menuTitle, systemImage: job.state.symbolName)
                }
            } label: {
                Label("Recent Conversions", systemImage: "clock.arrow.circlepath")
            }
        }
    }

    @ViewBuilder
    private var quickSettingsMenu: some View {
        Menu {
            @Bindable var bindable = settings
            Toggle(isOn: $bindable.revealInFinderOnComplete) {
                Label("Reveal in Finder on Complete", systemImage: "folder")
            }
            Toggle(isOn: $bindable.playSoundOnComplete) {
                Label("Play Sound on Complete", systemImage: "speaker.wave.2")
            }
            Divider()
            Menu {
                ForEach(1...8, id: \.self) { count in
                    Button {
                        settings.maxParallelJobs = count
                    } label: {
                        if settings.maxParallelJobs == count {
                            Label("\(count)", systemImage: "checkmark")
                        } else {
                            Text("\(count)")
                        }
                    }
                }
            } label: {
                Label("Parallel Jobs: \(settings.maxParallelJobs)", systemImage: "number")
            }
        } label: {
            Label("Quick Settings", systemImage: "slider.horizontal.3")
        }
    }

    @ViewBuilder
    private var logsMenu: some View {
        Menu {
            Button("Open Log File") { LoggerService.openLogFile() }
            Button("Open Log Folder") { LoggerService.openLogDirectory() }
        } label: {
            Label("Logs", systemImage: "doc.text")
        }
    }

    private var hasFinishedJobs: Bool {
        orchestrator.jobs.contains { $0.state == .completed || $0.state == .failed || $0.state == .cancelled }
    }

    private func refreshClipboard() {
        let currentChangeCount = NSPasteboard.general.changeCount
        guard currentChangeCount != clipboardChangeCount else { return }
        clipboardChangeCount = currentChangeCount
        clipboardURLs = ClipboardReader.readFileURLs()
    }

    private func refreshOrchestratorSnapshot() {
        let snapshot = orchestrator.jobs
            .map { "\($0.id.uuidString)|\($0.state)|\($0.progress)|\($0.etaSecondsRemaining ?? -1)|\($0.isIndeterminate)" }
            .joined(separator: ";")
        guard snapshot != lastJobsSnapshot else { return }
        lastJobsSnapshot = snapshot
        menuRefreshToken += 1
    }

    private func quitApplication() {
        let hasActive = orchestrator.jobs.contains { $0.state == .running || $0.state == .queued }
            || ConversionOrchestrator.hasActiveConversions()
        guard QuitConfirmation.confirmQuit(hasActiveConversion: hasActive) else { return }
        NSApplication.shared.terminate(nil)
    }

    private func convert(with preset: ConversionPreset) {
        refreshClipboard()
        guard selection.canConvertAllFiles(with: preset) else {
            NSSound.beep()
            return
        }
        for url in clipboardURLs {
            orchestrator.addJob(inputURL: url, preset: preset)
        }
    }
}

extension OutputType.Category {
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

extension ConversionJob {
    var menuTitle: String {
        let truncated = fileName.truncatedWithExtension(maxLength: 36)
        switch state {
        case .queued: return "\(truncated) - Queued"
        case .running where isIndeterminate: return "\(truncated) - Converting…"
        case .running:
            if let eta = ETAFormatting.format(seconds: etaSecondsRemaining) {
                return "\(truncated) - \(Int(progress.rounded()))% (\(eta))"
            }
            return "\(truncated) - \(Int(progress.rounded()))%"
        case .completed: return "\(truncated) - Done"
        case .failed:
            if let error = errorMessage, !error.isEmpty {
                return "\(truncated) - Failed: \(error.prefix(40))"
            }
            return "\(truncated) - Failed"
        case .cancelled: return "\(truncated) - Cancelled"
        }
    }

    @ViewBuilder
    var activeProgressRow: some View {
        if isIndeterminate {
            Text("Converting…")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        } else {
            HStack(spacing: 6) {
                Text("\(Int(progress.rounded()))%")
                if let eta = ETAFormatting.format(seconds: etaSecondsRemaining) {
                    Text("·")
                    Text(eta)
                }
            }
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(.secondary)
        }
    }
}

extension ConversionState {
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

extension String {
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
