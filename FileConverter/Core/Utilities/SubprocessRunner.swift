import Foundation

enum SubprocessRunner {
    struct Result: Sendable {
        let stdout: String
        let stderr: String
    }

    /// Runs a subprocess with live stderr piping. When `parseFFmpegProgress` is true, invokes `onProgress` as ffmpeg reports duration/time.
    static func run(
        executable: String,
        arguments: [String],
        environment: [String: String]? = nil,
        parseFFmpegProgress: Bool = true,
        onProgress: (@Sendable (ConversionProgressSnapshot) -> Void)? = nil,
        onProcessStarted: (@Sendable (Int32) -> Void)? = nil
    ) async throws -> Result {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments

            if let env = environment {
                var merged = ProcessInfo.processInfo.environment
                for (key, value) in env {
                    if key == "PATH" {
                        let existing = merged["PATH"] ?? ""
                        merged["PATH"] = "\(value):\(existing)"
                    } else {
                        merged[key] = value
                    }
                }
                process.environment = merged
            }

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe
            process.standardInput = FileHandle.nullDevice

            let stdoutBuffer = DataBuffer()
            let stderrText = TextBuffer()

            let outHandle = stdoutPipe.fileHandleForReading
            let errHandle = stderrPipe.fileHandleForReading

            outHandle.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else { return }
                stdoutBuffer.data.append(data)
            }

            errHandle.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else { return }
                guard let chunk = String(data: data, encoding: .utf8) else { return }
                stderrText.value += chunk
                if parseFFmpegProgress, let onProgress,
                   let snapshot = FFmpegProgressParser.snapshot(from: stderrText.value) {
                    onProgress(snapshot)
                }
            }

            process.terminationHandler = { proc in
                outHandle.readabilityHandler = nil
                errHandle.readabilityHandler = nil

                let trailingOut = try? outHandle.readToEnd()
                if let trailingOut, !trailingOut.isEmpty {
                    stdoutBuffer.data.append(trailingOut)
                }
                let trailingErr = try? errHandle.readToEnd()
                if let trailingErr, !trailingErr.isEmpty,
                   let chunk = String(data: trailingErr, encoding: .utf8) {
                    stderrText.value += chunk
                    if parseFFmpegProgress, let onProgress,
                       let snapshot = FFmpegProgressParser.snapshot(from: stderrText.value) {
                        onProgress(snapshot)
                    }
                }

                try? outHandle.close()
                try? errHandle.close()

                let stdout = String(data: stdoutBuffer.data, encoding: .utf8) ?? ""
                let stderr = stderrText.value

                guard proc.terminationStatus == 0 else {
                    continuation.resume(throwing: ConversionError.processFailed(
                        exitCode: proc.terminationStatus,
                        stderr: stderr
                    ))
                    return
                }

                continuation.resume(returning: Result(stdout: stdout, stderr: stderr))
            }

            do {
                try process.run()
                onProcessStarted?(process.processIdentifier)
            } catch {
                outHandle.readabilityHandler = nil
                errHandle.readabilityHandler = nil
                continuation.resume(throwing: error)
            }
        }
    }
}

private final class TextBuffer: @unchecked Sendable {
    var value = ""
}

private final class DataBuffer: @unchecked Sendable {
    var data = Data()
}
