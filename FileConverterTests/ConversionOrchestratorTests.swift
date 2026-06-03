import XCTest
@testable import convertfile43

@MainActor
final class ConversionOrchestratorTests: XCTestCase {
    var settings: AppSettings!
    var orchestrator: ConversionOrchestrator!

    override func setUp() async throws {
        try await super.setUp()
        settings = AppSettings()
        orchestrator = ConversionOrchestrator(settings: settings)
        orchestrator.isProcessing = true
    }

    func test_addJob_addsQueuedJob() {
        let url = URL(fileURLWithPath: "/tmp/test.mp4")
        let preset = ConversionPreset(name: "MKV", inputExtensions: ["mp4"], outputType: .mkv)
        orchestrator.addJob(inputURL: url, preset: preset)
        XCTAssertEqual(orchestrator.jobs.count, 1)
        let job = orchestrator.jobs[0]
        XCTAssertEqual(job.state, .queued)
        XCTAssertEqual(job.presetName, "MKV")
        XCTAssertEqual(job.inputURL, url)
        XCTAssertTrue(job.outputURL.path.hasSuffix("_converted.mkv"))
    }

    func test_addJob_multipleJobs() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.mp4"),
            URL(fileURLWithPath: "/tmp/b.mp4"),
            URL(fileURLWithPath: "/tmp/c.mp4"),
        ]
        for url in urls {
            orchestrator.addJob(inputURL: url, preset: ConversionPreset(name: "MKV", inputExtensions: ["mp4"], outputType: .mkv))
        }
        XCTAssertEqual(orchestrator.jobs.count, 3)
        for job in orchestrator.jobs {
            XCTAssertEqual(job.state, .queued)
        }
    }

    func test_cancelJob_changesState() {
        let url = URL(fileURLWithPath: "/tmp/test.mp4")
        orchestrator.addJob(inputURL: url, preset: ConversionPreset(name: "MKV", inputExtensions: ["mp4"], outputType: .mkv))
        guard let job = orchestrator.jobs.first else {
            XCTFail("Expected a queued job")
            return
        }
        orchestrator.jobs[0].state = .running
        orchestrator.cancelJob(id: job.id)
        XCTAssertEqual(orchestrator.jobs[0].state, .cancelled)
    }

    func test_cancelJob_unknownId() {
        orchestrator.cancelJob(id: UUID())
        XCTAssertEqual(orchestrator.jobs.count, 0)
    }

    func test_clearCompleted_removesCompleted() {
        orchestrator.addJob(inputURL: URL(fileURLWithPath: "/tmp/a.mp4"), preset: ConversionPreset(name: "MKV", inputExtensions: ["mp4"], outputType: .mkv))
        orchestrator.addJob(inputURL: URL(fileURLWithPath: "/tmp/b.mp4"), preset: ConversionPreset(name: "MKV", inputExtensions: ["mp4"], outputType: .mkv))
        orchestrator.jobs[0].state = .completed
        orchestrator.jobs[1].state = .failed
        orchestrator.clearCompleted()
        XCTAssertEqual(orchestrator.jobs.count, 0)
    }

    func test_clearCompleted_keepsRunning() {
        let mkv = ConversionPreset(name: "MKV", inputExtensions: ["mp4"], outputType: .mkv)
        orchestrator.addJob(inputURL: URL(fileURLWithPath: "/tmp/a.mp4"), preset: mkv)
        orchestrator.addJob(inputURL: URL(fileURLWithPath: "/tmp/b.mp4"), preset: mkv)
        orchestrator.jobs[0].state = .completed
        orchestrator.clearCompleted()
        XCTAssertEqual(orchestrator.jobs.count, 1)
        XCTAssertEqual(orchestrator.jobs[0].state, .queued)
    }

    func test_clearCompleted_keepsQueued() {
        orchestrator.addJob(inputURL: URL(fileURLWithPath: "/tmp/a.mp4"), preset: ConversionPreset(name: "MKV", inputExtensions: ["mp4"], outputType: .mkv))
        orchestrator.addJob(inputURL: URL(fileURLWithPath: "/tmp/b.mp4"), preset: ConversionPreset(name: "MKV", inputExtensions: ["mp4"], outputType: .mkv))
        orchestrator.jobs[0].state = .completed
        orchestrator.clearCompleted()
        XCTAssertEqual(orchestrator.jobs.count, 1)
        XCTAssertEqual(orchestrator.jobs[0].state, .queued)
    }

    func test_removeJobById() {
        orchestrator.addJob(inputURL: URL(fileURLWithPath: "/tmp/test.mp4"), preset: ConversionPreset(name: "MKV", inputExtensions: ["mp4"], outputType: .mkv))
        guard let job = orchestrator.jobs.first else {
            XCTFail("Expected a queued job")
            return
        }
        orchestrator.removeJob(id: job.id)
        XCTAssertEqual(orchestrator.jobs.count, 0)
    }

    func test_addJob_generatesCorrectOutputPath() {
        let url = URL(fileURLWithPath: "/Users/test/video.mp4")
        let preset = ConversionPreset(name: "JPEG High Quality", inputExtensions: ["mp4"], outputType: .jpg)
        orchestrator.addJob(inputURL: url, preset: preset)
        guard let job = orchestrator.jobs.first else {
            XCTFail("Expected a queued job")
            return
        }
        XCTAssertEqual(job.outputURL.path, "/Users/test/video_converted.jpg")
    }

    func test_addJob_audioPreset_generatesCorrectOutputPath() {
        let url = URL(fileURLWithPath: "/Users/test/song.wav")
        let preset = ConversionPreset(name: "MP3 320kbps", inputExtensions: ["wav", "flac"], outputType: .mp3)
        orchestrator.addJob(inputURL: url, preset: preset)
        guard let job = orchestrator.jobs.first else {
            XCTFail("Expected a queued job")
            return
        }
        XCTAssertEqual(job.outputURL.path, "/Users/test/song_converted.mp3")
    }

    func test_isProcessing_defaultState() {
        XCTAssertTrue(orchestrator.isProcessing)
    }

    func test_jobsArrayOrdering() {
        let urls = [
            URL(fileURLWithPath: "/tmp/first.mp4"),
            URL(fileURLWithPath: "/tmp/second.mp4"),
            URL(fileURLWithPath: "/tmp/third.mp4"),
        ]
        for url in urls {
            orchestrator.addJob(inputURL: url, preset: ConversionPreset(name: "MKV", inputExtensions: ["mp4"], outputType: .mkv))
        }
        XCTAssertEqual(orchestrator.jobs.count, 3)
        XCTAssertEqual(orchestrator.jobs[0].inputURL.lastPathComponent, "first.mp4")
        XCTAssertEqual(orchestrator.jobs[1].inputURL.lastPathComponent, "second.mp4")
        XCTAssertEqual(orchestrator.jobs[2].inputURL.lastPathComponent, "third.mp4")
    }
}
