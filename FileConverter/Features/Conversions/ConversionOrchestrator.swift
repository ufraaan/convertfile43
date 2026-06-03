import Foundation
import AppKit

private let sharedProcessTracker = ProcessTracker()

@MainActor @Observable
final class ConversionOrchestrator {
    var jobs: [ConversionJob] = []
    var isProcessing = false

    private let settings: AppSettings

    /// Stops all tracked conversion subprocesses (including child processes like ffmpeg under ffconv).
    static func hasActiveConversions() -> Bool {
        let tracker = sharedProcessTracker
        return !tracker.allRootPIDs().isEmpty
    }

    @discardableResult
    static func cancelAll() -> [pid_t] {
        let roots = sharedProcessTracker.allRootPIDs()
        sharedProcessTracker.clearAll()
        guard !roots.isEmpty else { return [] }
        ProcessTermination.terminateAll(roots: roots)
        ProcessTermination.terminateBundledConversionTools()
        return roots
    }

    /// Stops conversions on quit. Returns true if bundled ffmpeg/ffconv may still be running.
    @discardableResult
    static func shutdownForQuit() -> Bool {
        let roots = cancelAll()
        let trees = ProcessTermination.processTreePIDs(roots: roots)
        let deadline = Date().addingTimeInterval(3.0)
        while Date() < deadline, trees.contains(where: ProcessTermination.isRunning) {
            Thread.sleep(forTimeInterval: 0.05)
        }
        ProcessTermination.terminateBundledConversionTools()
        return ProcessTermination.bundledToolsStillRunning()
    }

    init(settings: AppSettings) {
        self.settings = settings
    }

    @MainActor
    func addJob(inputURL: URL, preset: ConversionPreset) {
        let outputExtension = preset.outputType.fileExtension
        let outputURL = inputURL
            .deletingLastPathComponent()
            .appendingPathComponent(inputURL.deletingPathExtension().lastPathComponent + "_converted")
            .appendingPathExtension(outputExtension)

        let job = ConversionJob(
            id: UUID(),
            inputURL: inputURL,
            outputURL: outputURL,
            presetName: preset.name,
            state: .queued,
            progress: 0,
            etaSecondsRemaining: nil,
            isIndeterminate: false,
            errorMessage: nil
        )
        jobs.append(job)

        LoggerService.info("Queued conversion: \(job.fileName) → \(preset.name) (output: \(job.outputFileName))",
            component: "ConversionOrchestrator")

        if !isProcessing {
            Task { @MainActor in processNext() }
        }
    }

    @MainActor
    func removeJob(id: UUID) {
        jobs.removeAll { $0.id == id }
    }

    private nonisolated let cleanupDelay: Duration = .seconds(4)

    @MainActor
    func cancelJob(id: UUID) {
        guard let index = jobs.firstIndex(where: { $0.id == id }) else { return }
        jobs[index].state = .cancelled
        let pids = sharedProcessTracker.pids(for: id)
        sharedProcessTracker.clear(jobId: id)
        if !pids.isEmpty {
            ProcessTermination.terminateAll(roots: pids, graceSeconds: 0.5)
            ProcessTermination.terminateBundledConversionTools()
        }
        LoggerService.info("Cancelled job: \(jobs[index].fileName)", component: "ConversionOrchestrator")
    }

    @MainActor
    func clearCompleted() {
        let count = jobs.filter { $0.state == .completed || $0.state == .failed || $0.state == .cancelled }.count
        jobs.removeAll { $0.state == .completed || $0.state == .failed || $0.state == .cancelled }
        LoggerService.info("Cleared \(count) finished job(s)", component: "ConversionOrchestrator")
    }

    @MainActor
    private func processNext() {
        guard !isProcessing else { return }
        guard let index = jobs.firstIndex(where: { $0.state == .queued }) else {
            isProcessing = false
            return
        }

        isProcessing = true
        let job = jobs[index]
        let preset = settings.presets.first { $0.name == job.presetName }
            ?? ConversionPreset(name: job.presetName, inputExtensions: [], outputType: .mp4)
        jobs[index].state = .running
        jobs[index].isIndeterminate = Self.usesIndeterminateProgress(job: job, preset: preset)

        LoggerService.info("Starting conversion: \(job.fileName) → \(preset.name)", component: "ConversionOrchestrator")

        Task {
            do {
                try await convert(job: job, preset: preset)
                await MainActor.run {
                    guard let idx = self.jobs.firstIndex(where: { $0.id == job.id }) else { return }
                    self.jobs[idx].state = .completed
                    self.jobs[idx].progress = 100
                    self.jobs[idx].etaSecondsRemaining = nil
                    self.jobs[idx].isIndeterminate = false
                    self.isProcessing = false
                    LoggerService.info("Conversion completed: \(job.fileName) → \(job.outputFileName)",
                        component: "ConversionOrchestrator")
                    NotificationService.sendCompletionNotification(job: self.jobs[idx])
                    if self.settings.playSoundOnComplete {
                        NSSound(named: "Ping")?.play()
                    }
                    if self.settings.revealInFinderOnComplete {
                        NSWorkspace.shared.activateFileViewerSelecting([self.jobs[idx].outputURL])
                    }
                    Task {
                        try? await Task.sleep(for: self.cleanupDelay)
                        self.removeJob(id: job.id)
                    }
                    Task { self.processNext() }
                }
            } catch {
                await MainActor.run {
                    guard let idx = self.jobs.firstIndex(where: { $0.id == job.id }) else { return }
                    self.jobs[idx].state = .failed
                    self.jobs[idx].errorMessage = error.localizedDescription
                    self.isProcessing = false
                    LoggerService.error("Conversion failed: \(job.fileName) — \(error.localizedDescription)",
                        component: "ConversionOrchestrator")
                    NotificationService.sendErrorNotification(job: self.jobs[idx])
                    Task {
                        try? await Task.sleep(for: self.cleanupDelay)
                        self.removeJob(id: job.id)
                    }
                    Task { self.processNext() }
                }
            }
        }
    }

    private nonisolated func convert(job: ConversionJob, preset: ConversionPreset) async throws {
        let input = job.inputURL.path
        let output = job.outputURL.path

        let jobId = job.id
        let progressHandler: @Sendable (ConversionProgressSnapshot) -> Void = { [weak self] snapshot in
            guard snapshot.percent >= 0 else { return }
            LoggerService.debug(
                String(format: "Progress %.1f%% (eta: %@)", snapshot.percent, snapshot.etaSeconds.map { String(format: "%.0fs", $0) } ?? "—"),
                component: "ConversionOrchestrator"
            )
            Task { @MainActor in
                guard let self,
                      let idx = self.jobs.firstIndex(where: { $0.id == jobId }) else { return }
                if self.jobs[idx].state == .running {
                    self.jobs[idx].progress = snapshot.percent
                    self.jobs[idx].etaSecondsRemaining = snapshot.etaSeconds
                }
            }
        }

        let isSVGInput = ImageMagickService.isSVGInput(input)
        let isSVGOutput = preset.outputType == .svg

        if isSVGInput || isSVGOutput {
            try await runImageMagick(jobId: job.id, input: input, output: output, settings: preset.settings, isSVGInput: isSVGInput, isSVGOutput: isSVGOutput, progressHandler: progressHandler)
            return
        }

        switch preset.outputType {
        case .pdf where ["doc", "docx", "odt", "ppt", "pptx", "odp", "xls", "xlsx", "ods"].contains(job.inputURL.pathExtension.lowercased()):
            try await runLibreOffice(jobId: job.id, input: job.inputURL.path, progressHandler: progressHandler)
        default:
            if BundlePaths.isFFConvAvailable {
                try await runFFconv(jobId: job.id, input: input, output: output, settings: preset.settings, outputType: preset.outputType, progressHandler: progressHandler)
            } else {
                LoggerService.warning(
                    "Bundled ffconv not found; falling back to ffmpeg with live stderr progress",
                    component: "ConversionOrchestrator"
                )
                try await runFFmpeg(jobId: job.id, input: input, output: output, settings: preset.settings, outputType: preset.outputType, progressHandler: progressHandler)
            }
        }
    }

    private static func usesIndeterminateProgress(job: ConversionJob, preset: ConversionPreset) -> Bool {
        let input = job.inputURL.path
        if ImageMagickService.isSVGInput(input) || preset.outputType == .svg {
            return true
        }
        if preset.outputType == .pdf {
            let ext = job.inputURL.pathExtension.lowercased()
            if ["doc", "docx", "odt", "ppt", "pptx", "odp", "xls", "xlsx", "ods"].contains(ext) {
                return true
            }
        }
        return false
    }

    private nonisolated func runImageMagick(jobId: UUID, input: String, output: String, settings: ConversionSettings, isSVGInput: Bool, isSVGOutput: Bool, progressHandler: @Sendable @escaping (ConversionProgressSnapshot) -> Void) async throws {
        let magick = BundlePaths.magick
        let args = ImageMagickService.buildArguments(input: input, output: output, settings: settings)
        LoggerService.debug("ImageMagick: \(magick) | Args: \(args.joined(separator: " "))", component: "ConversionOrchestrator")
        let magickDir = (magick as NSString).deletingLastPathComponent
        try await runProcess(jobId: jobId, executable: magick, arguments: args, environment: ["PATH": magickDir], parseFFmpegProgress: false, progressHandler: progressHandler)
    }

    private nonisolated func runFFmpeg(jobId: UUID, input: String, output: String, settings: ConversionSettings, outputType: OutputType, progressHandler: @Sendable @escaping (ConversionProgressSnapshot) -> Void) async throws {
        let args = FFmpegService.buildArguments(input: input, output: output, settings: settings, outputType: outputType)
        let executable = BundlePaths.ffmpeg
        LoggerService.debug("Executable: \(executable) | Output type: \(outputType.rawValue) | Args: \(args.joined(separator: " "))", component: "ConversionOrchestrator")
        try await runProcess(jobId: jobId, executable: executable, arguments: args, progressHandler: progressHandler)
    }

    private nonisolated func runFFconv(jobId: UUID, input: String, output: String, settings: ConversionSettings, outputType: OutputType, progressHandler: @Sendable @escaping (ConversionProgressSnapshot) -> Void) async throws {
        let ffconv = BundlePaths.ffconv
        let ffmpeg = BundlePaths.ffmpeg
        var args: [String] = [
            "--ffmpeg", ffmpeg,
            "--input", input,
            "--output", output,
        ]
        args += FFconvService.buildArguments(outputType: outputType, settings: settings)

        LoggerService.debug("ffconv: \(ffconv) | type: \(outputType.rawValue) | args: \(args.joined(separator: " "))", component: "ConversionOrchestrator")

        let outputPipe = Pipe()
        let stderrPipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffconv)
        process.arguments = args
        process.standardOutput = outputPipe
        process.standardError = stderrPipe

        return try await withCheckedThrowingContinuation { continuation in
            let outHandle = outputPipe.fileHandleForReading
            let errHandle = stderrPipe.fileHandleForReading
            let buffer = LineBuffer()
            let stderrBuffer = DataBuffer()

            errHandle.readabilityHandler = { handle in
                stderrBuffer.data.append(handle.availableData)
            }

            @Sendable func parseStdoutChunk(_ data: Data, flushRemainder: Bool = false) {
                guard !data.isEmpty else { return }
                buffer.value += String(data: data, encoding: .utf8) ?? ""
                var lines = buffer.value.components(separatedBy: "\n")
                if flushRemainder {
                    buffer.value = ""
                } else {
                    buffer.value = lines.last ?? ""
                    lines = Array(lines.dropLast())
                }
                for line in lines where !line.isEmpty {
                    guard let jsonData = line.data(using: .utf8),
                          let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else { continue }
                    let type = json["type"] as? String
                    if type == "started", let ffmpegPID = json["ffmpeg_pid"] as? Int {
                        sharedProcessTracker.register(pid_t(ffmpegPID), for: jobId)
                    } else if type == "progress", let pct = json["percent"] as? Double {
                        var etaValue: TimeInterval?
                        if let eta = json["eta_seconds"] as? Double, eta >= 1 {
                            etaValue = eta
                        }
                        progressHandler(ConversionProgressSnapshot(percent: pct, etaSeconds: etaValue))
                    }
                }
            }

            outHandle.readabilityHandler = { handle in
                parseStdoutChunk(handle.availableData)
            }

            process.terminationHandler = { proc in
                sharedProcessTracker.clear(jobId: jobId)
                outHandle.readabilityHandler = nil
                errHandle.readabilityHandler = nil
                if let trailing = try? outHandle.readToEnd() {
                    parseStdoutChunk(trailing, flushRemainder: true)
                } else {
                    parseStdoutChunk(Data(), flushRemainder: true)
                }
                try? outHandle.close()
                try? errHandle.close()

                let stderrText = String(data: stderrBuffer.data, encoding: .utf8) ?? ""

                guard proc.terminationStatus == 0 else {
                    LoggerService.error("ffconv exited with code \(proc.terminationStatus): \(stderrText)", component: "ConversionOrchestrator")
                    continuation.resume(throwing: ConversionError.processFailed(exitCode: proc.terminationStatus, stderr: stderrText))
                    return
                }

                LoggerService.debug("ffconv completed successfully", component: "ConversionOrchestrator")
                continuation.resume(returning: ())
            }

            do {
                try process.run()
                sharedProcessTracker.register(process.processIdentifier, for: jobId)
            } catch {
                sharedProcessTracker.clear(jobId: jobId)
                outHandle.readabilityHandler = nil
                errHandle.readabilityHandler = nil
                continuation.resume(throwing: error)
            }
        }
    }

    private nonisolated func runLibreOffice(jobId: UUID, input: String, progressHandler: @Sendable @escaping (ConversionProgressSnapshot) -> Void) async throws {
        guard LibreOfficeService.isAvailable else {
            LoggerService.error("LibreOffice not found at /Applications/LibreOffice.app", component: "ConversionOrchestrator")
            throw ConversionError.libreOfficeNotFound
        }
        let outputDir = URL(fileURLWithPath: input).deletingLastPathComponent().path
        let args = LibreOfficeService.buildConvertToPDFArguments(input: input, outputDir: outputDir)
        LoggerService.debug("LibreOffice with args: \(args.joined(separator: " "))", component: "ConversionOrchestrator")
        try await runProcess(jobId: jobId, executable: LibreOfficeService.executablePath, arguments: args, parseFFmpegProgress: false, progressHandler: progressHandler)
    }

    @discardableResult
    private nonisolated func runProcess(
        jobId: UUID,
        executable: String,
        arguments: [String],
        environment: [String: String]? = nil,
        parseFFmpegProgress: Bool = true,
        progressHandler: @Sendable @escaping (ConversionProgressSnapshot) -> Void
    ) async throws -> String {
        LoggerService.debug("Running: \(executable) with \(arguments.count) arg(s)", component: "ConversionOrchestrator")

        let tracker = sharedProcessTracker
        let onProgress: (@Sendable (ConversionProgressSnapshot) -> Void)? = parseFFmpegProgress ? progressHandler : nil

        do {
            let result = try await SubprocessRunner.run(
                executable: executable,
                arguments: arguments,
                environment: environment,
                parseFFmpegProgress: parseFFmpegProgress,
                onProgress: onProgress,
                onProcessStarted: { pid in
                    tracker.register(pid, for: jobId)
                }
            )
            tracker.clear(jobId: jobId)
            return result.stdout
        } catch {
            tracker.clear(jobId: jobId)
            throw error
        }
    }
}

enum ConversionError: Error, LocalizedError {
    case libreOfficeNotFound
    case processFailed(exitCode: Int32, stderr: String)

    var errorDescription: String? {
        switch self {
        case .libreOfficeNotFound:
            return "LibreOffice is not installed. Install it from libreoffice.org to convert documents."
        case .processFailed(let code, let stderr):
            return "Conversion failed (exit code \(code)): \(stderr)"
        }
    }
}

private final class LineBuffer: @unchecked Sendable {
    var value = ""
}

private final class DataBuffer: @unchecked Sendable {
    var data = Data()
}

private final class ProcessTracker: @unchecked Sendable {
    private var jobs: [UUID: Set<pid_t>] = [:]

    func register(_ pid: pid_t, for jobId: UUID) {
        jobs[jobId, default: []].insert(pid)
    }

    func pids(for jobId: UUID) -> [pid_t] {
        Array(jobs[jobId] ?? [])
    }

    func allRootPIDs() -> [pid_t] {
        Array(jobs.values.flatMap { $0 })
    }

    func clear(jobId: UUID) {
        jobs[jobId] = nil
    }

    func clearAll() {
        jobs.removeAll()
    }
}
