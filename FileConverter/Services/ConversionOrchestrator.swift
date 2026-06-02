import Foundation
import AppKit

@MainActor @Observable
final class ConversionOrchestrator {
    var jobs: [ConversionJob] = []
    var isProcessing = false

    private let settings: AppSettings

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
        jobs[index].state = .running

        let job = jobs[index]
        let preset = settings.presets.first { $0.name == job.presetName }
            ?? ConversionPreset(name: job.presetName, inputExtensions: [], outputType: .mp4)

        LoggerService.info("Starting conversion: \(job.fileName) → \(preset.name)", component: "ConversionOrchestrator")

        Task {
            do {
                try await convert(job: job, preset: preset)
                await MainActor.run {
                    guard let idx = self.jobs.firstIndex(where: { $0.id == job.id }) else { return }
                    self.jobs[idx].state = .completed
                    self.jobs[idx].progress = 100
                    self.isProcessing = false
                    LoggerService.info("Conversion completed: \(job.fileName) → \(job.outputFileName)",
                        component: "ConversionOrchestrator")
                    NotificationService.sendCompletionNotification(job: self.jobs[idx])
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

        switch preset.outputType {
        case .pdf where ["doc", "docx", "odt", "ppt", "pptx", "odp", "xls", "xlsx", "ods"].contains(job.inputURL.pathExtension.lowercased()):
            try await runLibreOffice(input: job.inputURL.path)
        default:
            try await runFFmpeg(input: input, output: output, settings: preset.settings, outputType: preset.outputType)
        }
    }

    private nonisolated func runFFmpeg(input: String, output: String, settings: ConversionSettings, outputType: OutputType) async throws {
        let args = FFmpegService.buildArguments(input: input, output: output, settings: settings, outputType: outputType)
        let executable = BundlePaths.ffmpeg
        LoggerService.debug("Executable: \(executable) | Output type: \(outputType.rawValue) | Args: \(args.joined(separator: " "))", component: "ConversionOrchestrator")
        try await runProcess(executable: executable, arguments: args)
    }

    private nonisolated func runLibreOffice(input: String) async throws {
        guard LibreOfficeService.isAvailable else {
            LoggerService.error("LibreOffice not found at /Applications/LibreOffice.app", component: "ConversionOrchestrator")
            throw ConversionError.libreOfficeNotFound
        }
        let outputDir = URL(fileURLWithPath: input).deletingLastPathComponent().path
        let args = LibreOfficeService.buildConvertToPDFArguments(input: input, outputDir: outputDir)
        LoggerService.debug("LibreOffice with args: \(args.joined(separator: " "))", component: "ConversionOrchestrator")
        try await runProcess(executable: LibreOfficeService.executablePath, arguments: args)
    }

    @discardableResult
    private nonisolated func runProcess(executable: String, arguments: [String]) async throws -> String {
        let stdoutURL = FileManager.default.temporaryDirectory.appendingPathComponent("cf43-stdout-\(UUID().uuidString).log")
        let stderrURL = FileManager.default.temporaryDirectory.appendingPathComponent("cf43-stderr-\(UUID().uuidString).log")
        FileManager.default.createFile(atPath: stdoutURL.path, contents: nil)
        FileManager.default.createFile(atPath: stderrURL.path, contents: nil)

        defer {
            try? FileManager.default.removeItem(at: stdoutURL)
            try? FileManager.default.removeItem(at: stderrURL)
        }

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments

            let stdoutHandle: FileHandle
            let stderrHandle: FileHandle
            do {
                stdoutHandle = try FileHandle(forWritingTo: stdoutURL)
                stderrHandle = try FileHandle(forWritingTo: stderrURL)
            } catch {
                continuation.resume(throwing: error)
                return
            }

            process.standardOutput = stdoutHandle
            process.standardError = stderrHandle
            process.standardInput = FileHandle.nullDevice

            LoggerService.debug("Running: \(executable) with \(arguments.count) arg(s)", component: "ConversionOrchestrator")

            process.terminationHandler = { proc in
                try? stdoutHandle.close()
                try? stderrHandle.close()

                let stdout = (try? String(contentsOf: stdoutURL, encoding: .utf8)) ?? ""
                let stderr = (try? String(contentsOf: stderrURL, encoding: .utf8)) ?? ""

                guard proc.terminationStatus == 0 else {
                    LoggerService.error("Process exited with code \(proc.terminationStatus): \(executable)\n  stderr: \(stderr)",
                        component: "ConversionOrchestrator")
                    continuation.resume(throwing: ConversionError.processFailed(exitCode: proc.terminationStatus, stderr: stderr))
                    return
                }

                LoggerService.debug("Process completed successfully: \(executable)", component: "ConversionOrchestrator")
                continuation.resume(returning: stdout)
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
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
