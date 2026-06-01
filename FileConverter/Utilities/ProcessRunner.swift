import Foundation

enum ProcessError: Error, LocalizedError {
    case binaryNotFound(String)
    case processFailed(exitCode: Int32, stderr: String)

    var errorDescription: String? {
        switch self {
        case .binaryNotFound(let name):
            return "\(name) not found. Please ensure it is bundled with the app."
        case .processFailed(let code, let stderr):
            return "Process exited with code \(code): \(stderr)"
        }
    }
}

enum ProcessRunner {
    static func run(
        executable: String,
        arguments: [String],
        inputURL: URL? = nil,
        outputURL: URL? = nil,
        progressHandler: (@Sendable (Double) -> Void)? = nil
    ) -> AsyncThrowingStream<Void, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
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

                    if process.terminationStatus != 0 {
                        continuation.finish(throwing: ProcessError.processFailed(
                            exitCode: process.terminationStatus,
                            stderr: stderr
                        ))
                    } else {
                        continuation.finish()
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
