import Foundation

@Observable
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

        if !isProcessing {
            Task { await processNext() }
        }
    }

    @MainActor
    func enqueue(request: FinderConversionRequest) {
        let preset = settings.presets.first { $0.name == request.presetName }
            ?? ConversionPreset(name: request.presetName, inputExtensions: [], outputType: .mp4)

        for fileURL in request.files {
            addJob(inputURL: fileURL, preset: preset)
        }
    }

    @MainActor
    func removeJob(id: UUID) {
        jobs.removeAll { $0.id == id }
    }

    @MainActor
    func cancelJob(id: UUID) {
        guard let index = jobs.firstIndex(where: { $0.id == id }) else { return }
        jobs[index].state = .cancelled
    }

    @MainActor
    func clearCompleted() {
        jobs.removeAll { $0.state == .completed || $0.state == .failed || $0.state == .cancelled }
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

        Task {
            do {
                try await convert(job: job, preset: preset)
                await MainActor.run {
                    guard let idx = self.jobs.firstIndex(where: { $0.id == job.id }) else { return }
                    self.jobs[idx].state = .completed
                    self.jobs[idx].progress = 100
                    self.isProcessing = false
                    NotificationService.sendCompletionNotification(job: self.jobs[idx])
                    if self.settings.revealInFinderOnComplete {
                        NSWorkspace.shared.activateFileViewerSelecting([self.jobs[idx].outputURL])
                    }
                    Task { await self.processNext() }
                }
            } catch {
                await MainActor.run {
                    guard let idx = self.jobs.firstIndex(where: { $0.id == job.id }) else { return }
                    self.jobs[idx].state = .failed
                    self.jobs[idx].errorMessage = error.localizedDescription
                    self.isProcessing = false
                    NotificationService.sendErrorNotification(job: self.jobs[idx])
                    Task { await self.processNext() }
                }
            }
        }
    }

    private func convert(job: ConversionJob, preset: ConversionPreset) async throws {
        let input = job.inputURL.path
        let output = job.outputURL.path

        switch preset.outputType {
        case .pdf where preset.inputExtensions.contains(job.inputURL.pathExtension.lowercased()):
            try await runImageMagick(input: input, output: output, settings: preset.settings)

        case .pdf where ["doc", "docx", "odt", "ppt", "pptx", "odp", "xls", "xlsx", "ods"].contains(job.inputURL.pathExtension.lowercased()):
            try await runLibreOffice(input: job.inputURL.path)

        case .pdf:
            try await runImageMagick(input: input, output: output, settings: preset.settings)

        case .jpg, .png, .webp, .ico:
            try await runImageMagick(input: input, output: output, settings: preset.settings)

        case .gif:
            try await runFFmpeg(input: input, output: output, settings: preset.settings, outputType: preset.outputType)

        case .mp4, .mkv, .avi, .webm, .ogv:
            try await runFFmpeg(input: input, output: output, settings: preset.settings, outputType: preset.outputType)

        case .mp3, .aac, .flac, .ogg, .wav:
            try await runFFmpeg(input: input, output: output, settings: preset.settings, outputType: preset.outputType)
        }
    }

    private func runFFmpeg(input: String, output: String, settings: ConversionSettings, outputType: OutputType) async throws {
        let args = FFmpegService.buildArguments(input: input, output: output, settings: settings, outputType: outputType)
        try await runProcess(executable: BundlePaths.ffmpeg, arguments: args)
    }

    private func runImageMagick(input: String, output: String, settings: ConversionSettings) async throws {
        let args = ImageMagickService.buildArguments(input: input, output: output, settings: settings)
        try await runProcess(executable: BundlePaths.imagemagick, arguments: args)
    }

    private func runLibreOffice(input: String) async throws {
        guard LibreOfficeService.isAvailable else {
            throw ConversionError.libreOfficeNotFound
        }
        let outputDir = URL(fileURLWithPath: input).deletingLastPathComponent().path
        let args = LibreOfficeService.buildConvertToPDFArguments(input: input, outputDir: outputDir)
        try await runProcess(executable: LibreOfficeService.executablePath, arguments: args)
    }

    @discardableResult
    private func runProcess(executable: String, arguments: [String]) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw ConversionError.processFailed(exitCode: process.terminationStatus, stderr: stderr)
        }

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: stdoutData, encoding: .utf8) ?? ""
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
