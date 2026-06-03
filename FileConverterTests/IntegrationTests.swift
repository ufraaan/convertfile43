import XCTest
@testable import convertfile43

final class ProcessRunTests: XCTestCase {

    func test_ffmpegVersionCompletes() async throws {
        let ffmpegPath = BundlePaths.ffmpeg
        let stdout = try await runProcess(executable: ffmpegPath, arguments: ["-version"])
        XCTAssertTrue(stdout.contains("ffmpeg version"), "Expected ffmpeg version output but got: \(stdout.prefix(200))")
    }

    func test_ffmpegValidExitCode() async throws {
        let ffmpegPath = BundlePaths.ffmpeg
        let args = ["-i", "/nonexistent/input.mp4", "-y", "/tmp/output.mp4"]
        do {
            let _ = try await runProcess(executable: ffmpegPath, arguments: args)
            XCTFail("Expected error for nonexistent input")
        } catch {
            guard let convError = error as? ConversionError else {
                XCTFail("Expected ConversionError but got: \(error)")
                return
            }
            if case .processFailed(let code, _) = convError {
                XCTAssertNotEqual(code, 0, "Expected non-zero exit code for missing input, got \(code)")
            } else {
                XCTFail("Expected processFailed but got: \(convError)")
            }
        }
    }

    func test_ffmpegQuickConversionCompletes() async throws {
        let ffmpegPath = BundlePaths.ffmpeg
        let testDir = FileManager.default.temporaryDirectory
        let inputURL = testDir.appendingPathComponent("test_vtc_input.mp4")
        let outputURL = testDir.appendingPathComponent("test_vtc_output.mkv")

        defer {
            try? FileManager.default.removeItem(at: inputURL)
            try? FileManager.default.removeItem(at: outputURL)
        }

        let genArgs = [
            "-f", "lavfi", "-i", "testsrc2=duration=2:size=640x360:rate=15",
            "-f", "lavfi", "-i", "sine=frequency=440:duration=2",
            "-c:v", "libx264", "-c:a", "aac", "-shortest", "-y",
            inputURL.path
        ]
        try await runProcess(executable: ffmpegPath, arguments: genArgs)

        let convertArgs = [
            "-i", inputURL.path, "-y", "-nostdin",
            "-codec:v", "libx264", "-codec:a", "aac",
            outputURL.path
        ]
        let stdout = try await runProcess(executable: ffmpegPath, arguments: convertArgs)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path), "Output file should exist")
        let fileSize = try FileManager.default.attributesOfItem(atPath: outputURL.path)[.size] as? Int64 ?? 0
        XCTAssertGreaterThan(fileSize, 1000, "Output file should be larger than 1KB")
    }

    func test_instantProcessDoesntHang() async throws {
        let stdout = try await runProcess(executable: "/bin/echo", arguments: ["hello world"])
        XCTAssertEqual(stdout.trimmingCharacters(in: .whitespacesAndNewlines), "hello world")
    }

    func test_processWithOnlyStderrCompletes() async throws {
        let stdout = try await runProcess(executable: "/bin/bash", arguments: ["-c", "echo 'error msg' >&2; exit 0"])
        XCTAssertEqual(stdout, "")
    }

    func test_zeroByteOutputDoesntBlock() async throws {
        let stdout = try await runProcess(executable: "/usr/bin/true", arguments: [])
        XCTAssertEqual(stdout, "")
    }

    func test_largeStderrOutputDoesntBlock() async throws {
        let stdout = try await runProcess(executable: "/bin/bash", arguments: [
            "-c", "for i in $(seq 1 5000); do echo 'line '$i; done"
        ])
        XCTAssertTrue(stdout.contains("line 1"))
        XCTAssertTrue(stdout.contains("line 5000"), "Should have read all 5000 lines, got only " + String(stdout.split(separator: "\n").count) + " lines")
    }

    func test_ffmpegLongConversionCompletes() async throws {
        let ffmpegPath = BundlePaths.ffmpeg
        let inputURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_long_input.mp4")
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_long_output.mkv")
        defer {
            try? FileManager.default.removeItem(at: inputURL)
            try? FileManager.default.removeItem(at: outputURL)
        }

        let genArgs = [
            "-f", "lavfi", "-i", "testsrc2=duration=30:size=1280x720:rate=30",
            "-f", "lavfi", "-i", "sine=frequency=440:duration=30",
            "-c:v", "libx264", "-c:a", "aac", "-shortest", "-y",
            inputURL.path
        ]
        try await runProcess(executable: ffmpegPath, arguments: genArgs)

        let convertArgs = [
            "-i", inputURL.path, "-y", "-nostdin",
            "-codec:v", "libx264", "-codec:a", "aac",
            outputURL.path
        ]
        let stdout = try await runProcess(executable: ffmpegPath, arguments: convertArgs)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path), "Output file should exist")
        let fileSize = try FileManager.default.attributesOfItem(atPath: outputURL.path)[.size] as? Int64 ?? 0
        XCTAssertGreaterThan(fileSize, 1000, "Output file should be larger than 1KB")
    }

    private nonisolated func runProcess(executable: String, arguments: [String]) async throws -> String {
        let stdoutURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-stdout-\(UUID().uuidString).log")
        let stderrURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-stderr-\(UUID().uuidString).log")
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

            process.terminationHandler = { proc in
                try? stdoutHandle.close()
                try? stderrHandle.close()
                let stdout = (try? String(contentsOf: stdoutURL, encoding: .utf8)) ?? ""
                let stderr = (try? String(contentsOf: stderrURL, encoding: .utf8)) ?? ""

                LoggerService.info("terminationHandler: pid=\(proc.processIdentifier) status=\(proc.terminationStatus) stdout=\(stdout.count)B stderr=\(stderr.count)B", component: "Test")

                guard proc.terminationStatus == 0 else {
                    continuation.resume(throwing: ConversionError.processFailed(exitCode: proc.terminationStatus, stderr: stderr))
                    return
                }
                continuation.resume(returning: stdout)
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Live progress monitoring

    func test_progressMonitoring_withLongVideo_reportsMultipleSamples() async throws {
        let fixture = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Tests/Fixtures/test_5min_input.mp4")
        try XCTSkipUnless(FileManager.default.fileExists(atPath: fixture.path),
                          "5-minute test fixture not present at \(fixture.path) — skipping. Generate via Tests/Fixtures/generate.sh")

        let ffmpegPath = BundlePaths.ffmpeg
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_longprog_output.mkv")
        defer {
            try? FileManager.default.removeItem(at: outputURL)
        }

        let samples = ProgressCollector()
        let handler: @Sendable (Double) -> Void = { pct in
            samples.append(pct)
        }

        _ = try await runProcessWithProgress(
            executable: ffmpegPath,
            arguments: [
                "-i", fixture.path, "-y", "-nostdin",
                "-codec:v", "h264_videotoolbox", "-codec:a", "aac",
                outputURL.path
            ],
            progressHandler: handler,
            pollIntervalMs: 500
        )

        let collected = samples.copy()
        XCTAssertGreaterThan(collected.count, 5, "Expected many progress samples for 5-min video, got \(collected.count): \(collected)")
        if let first = collected.first, let last = collected.last {
            XCTAssertGreaterThanOrEqual(last, first, "Progress should be non-decreasing: first=\(first) last=\(last)")
        }
        if let maxProgress = collected.max() {
            XCTAssertGreaterThan(maxProgress, 80, "Expected progress to reach > 80% for a 5-min video, got max=\(maxProgress)")
        }
    }

    func test_progressMonitoring_longRun_reachesNear100() async throws {
        let ffmpegPath = BundlePaths.ffmpeg
        let inputURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_longprog_input.mp4")
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_longprog_output.mkv")
        defer {
            try? FileManager.default.removeItem(at: inputURL)
            try? FileManager.default.removeItem(at: outputURL)
        }

        let genArgs = [
            "-f", "lavfi", "-i", "testsrc2=duration=10:size=640x360:rate=15",
            "-f", "lavfi", "-i", "sine=frequency=440:duration=10",
            "-c:v", "libx264", "-c:a", "aac", "-shortest", "-y",
            inputURL.path
        ]
        try await runProcess(executable: ffmpegPath, arguments: genArgs)

        let (_, stderr) = try await runProcessCapturingAll(
            executable: ffmpegPath,
            arguments: [
                "-i", inputURL.path, "-y", "-nostdin",
                "-codec:v", "libx264", "-codec:a", "aac",
                outputURL.path
            ]
        )

        let progress = FFmpegProgressParser.progress(from: stderr)
        XCTAssertGreaterThan(progress, 90, "Expected progress > 90% for a 10s conversion, got \(progress). stderr tail: \(stderr.suffix(300))")
    }
}

private final class ProgressCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var samples: [Double] = []

    func append(_ value: Double) {
        lock.lock()
        samples.append(value)
        lock.unlock()
    }

    func copy() -> [Double] {
        lock.lock()
        defer { lock.unlock() }
        return samples
    }
}

extension ProcessRunTests {
    fileprivate func runProcessWithProgress(
        executable: String,
        arguments: [String],
        progressHandler: @Sendable @escaping (Double) -> Void,
        pollIntervalMs: Int = 500
    ) async throws -> String {
        let stdoutURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-p-out-\(UUID().uuidString).log")
        let stderrURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-p-err-\(UUID().uuidString).log")
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

            let monitorBox = TestMonitorTaskBox()

            process.terminationHandler = { proc in
                monitorBox.task?.cancel()
                try? stdoutHandle.close()
                try? stderrHandle.close()
                let stdout = (try? String(contentsOf: stdoutURL, encoding: .utf8)) ?? ""
                let stderr = (try? String(contentsOf: stderrURL, encoding: .utf8)) ?? ""
                guard proc.terminationStatus == 0 else {
                    continuation.resume(throwing: ConversionError.processFailed(exitCode: proc.terminationStatus, stderr: stderr))
                    return
                }
                continuation.resume(returning: stdout)
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
                return
            }

            let stderrForMonitor = stderrURL
            let monitorTask = Task.detached(priority: .utility) {
                guard let readHandle = try? FileHandle(forReadingFrom: stderrForMonitor) else {
                    return
                }
                defer { try? readHandle.close() }

                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(pollIntervalMs))
                    if Task.isCancelled { break }
                    do {
                        try readHandle.seek(toOffset: 0)
                        let data = try readHandle.readToEnd() ?? Data()
                        if !data.isEmpty,
                           let text = String(data: data, encoding: .utf8) {
                            let pct = FFmpegProgressParser.progress(from: text)
                            if pct >= 0 {
                                progressHandler(pct)
                            }
                        }
                    } catch {
                        return
                    }
                }
            }
            monitorBox.task = monitorTask
        }
    }
}

private final class TestMonitorTaskBox: @unchecked Sendable {
    var task: Task<Void, Never>?
}

extension ProcessRunTests {
    fileprivate func runProcessCapturingAll(
        executable: String,
        arguments: [String]
    ) async throws -> (stdout: String, stderr: String) {
        let stdoutURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-c-stdout-\(UUID().uuidString).log")
        let stderrURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-c-stderr-\(UUID().uuidString).log")
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

            process.terminationHandler = { proc in
                try? stdoutHandle.close()
                try? stderrHandle.close()
                let stdout = (try? String(contentsOf: stdoutURL, encoding: .utf8)) ?? ""
                let stderr = (try? String(contentsOf: stderrURL, encoding: .utf8)) ?? ""
                guard proc.terminationStatus == 0 else {
                    continuation.resume(throwing: ConversionError.processFailed(exitCode: proc.terminationStatus, stderr: stderr))
                    return
                }
                continuation.resume(returning: (stdout, stderr))
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
