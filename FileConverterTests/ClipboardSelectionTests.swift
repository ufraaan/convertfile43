import XCTest
@testable import convertfile43

final class ClipboardSelectionTests: XCTestCase {
    func test_emptySelection() {
        let sel = ClipboardSelection(urls: [])
        XCTAssertEqual(sel.statusTitle, "No copied Finder files")
        XCTAssertEqual(sel.statusSymbolName, "doc.on.clipboard")
    }

    func test_singleFile() {
        let url = URL(fileURLWithPath: "/tmp/test.mp4")
        let sel = ClipboardSelection(urls: [url])
        XCTAssertEqual(sel.statusTitle, "1 copied file")
        XCTAssertEqual(sel.statusSymbolName, "doc.on.clipboard.fill")
    }

    func test_multipleFiles() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.mp4"),
            URL(fileURLWithPath: "/tmp/b.mp4"),
        ]
        let sel = ClipboardSelection(urls: urls)
        XCTAssertEqual(sel.statusTitle, "2 copied files")
    }

    func test_canConvertAllFiles_allMatch() {
        let url = URL(fileURLWithPath: "/tmp/test.mp4")
        let sel = ClipboardSelection(urls: [url])
        let preset = ConversionPreset(name: "MP4", inputExtensions: ["mp4", "mov", "m4v"], outputType: .mp4)
        XCTAssertTrue(sel.canConvertAllFiles(with: preset))
        XCTAssertTrue(sel.canConvertAnyFile(with: preset))
    }

    func test_canConvertAllFiles_partialMatch() {
        let urls = [
            URL(fileURLWithPath: "/tmp/test.mp4"),
            URL(fileURLWithPath: "/tmp/test.png"),
        ]
        let sel = ClipboardSelection(urls: urls)
        let preset = ConversionPreset(name: "MP4", inputExtensions: ["mp4", "mov"], outputType: .mp4)
        XCTAssertFalse(sel.canConvertAllFiles(with: preset))
        XCTAssertTrue(sel.canConvertAnyFile(with: preset))
    }

    func test_canConvertAllFiles_noMatch() {
        let url = URL(fileURLWithPath: "/tmp/test.png")
        let sel = ClipboardSelection(urls: [url])
        let preset = ConversionPreset(name: "MP3", inputExtensions: ["mp3", "wav", "flac"], outputType: .mp3)
        XCTAssertFalse(sel.canConvertAllFiles(with: preset))
        XCTAssertFalse(sel.canConvertAnyFile(with: preset))
    }

    func test_canConvertAllFiles_emptyURLs() {
        let sel = ClipboardSelection(urls: [])
        let preset = ConversionPreset(name: "MP4", inputExtensions: ["mp4"], outputType: .mp4)
        XCTAssertFalse(sel.canConvertAllFiles(with: preset))
        XCTAssertFalse(sel.canConvertAnyFile(with: preset))
    }

    func test_tooltip_noFiles() {
        let sel = ClipboardSelection(urls: [])
        let preset = ConversionPreset(name: "MP4", inputExtensions: ["mp4"], outputType: .mp4)
        XCTAssertEqual(sel.tooltip(for: preset), "Copy files in Finder first (⌘C)")
    }

    func test_tooltip_singleFile() {
        let url = URL(fileURLWithPath: "/tmp/test.mp4")
        let sel = ClipboardSelection(urls: [url])
        let preset = ConversionPreset(name: "MP4", inputExtensions: ["mp4", "mov"], outputType: .mp4)
        XCTAssertEqual(sel.tooltip(for: preset), "Convert file to MP4")
    }

    func test_tooltip_multipleFiles() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.mp4"),
            URL(fileURLWithPath: "/tmp/b.mp4"),
        ]
        let sel = ClipboardSelection(urls: urls)
        let preset = ConversionPreset(name: "MP4", inputExtensions: ["mp4", "mov"], outputType: .mp4)
        XCTAssertEqual(sel.tooltip(for: preset), "Convert 2 files to MP4")
    }

    func test_tooltip_unsupportedFiles() {
        let urls = [
            URL(fileURLWithPath: "/tmp/test.mp4"),
            URL(fileURLWithPath: "/tmp/test.png"),
        ]
        let sel = ClipboardSelection(urls: urls)
        let preset = ConversionPreset(name: "MP4", inputExtensions: ["mp4"], outputType: .mp4)
        XCTAssertEqual(sel.tooltip(for: preset), "Not available for test.png")
    }

    func test_tooltip_multipleUnsupported() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.mp4"),
            URL(fileURLWithPath: "/tmp/b.png"),
            URL(fileURLWithPath: "/tmp/c.gif"),
            URL(fileURLWithPath: "/tmp/d.webp"),
            URL(fileURLWithPath: "/tmp/e.svg"),
        ]
        let sel = ClipboardSelection(urls: urls)
        let preset = ConversionPreset(name: "MP4", inputExtensions: ["mp4"], outputType: .mp4)
        let tip = sel.tooltip(for: preset)
        XCTAssertTrue(tip.hasPrefix("Not available for"))
        XCTAssertTrue(tip.contains("b.png"))
        XCTAssertTrue(tip.contains("c.gif"))
        XCTAssertTrue(tip.contains("d.webp"))
        XCTAssertTrue(tip.contains(", and 1 more"))
    }
}

final class OutputTypeCategoryTests: XCTestCase {
    func test_allCases() {
        XCTAssertEqual(OutputType.Category.allCases, [.audio, .video, .image, .document])
    }

    func test_menuTitle() {
        XCTAssertEqual(OutputType.Category.audio.menuTitle, "Convert Audio")
        XCTAssertEqual(OutputType.Category.video.menuTitle, "Convert Video")
        XCTAssertEqual(OutputType.Category.image.menuTitle, "Convert Images")
        XCTAssertEqual(OutputType.Category.document.menuTitle, "Convert Documents")
    }

    func test_symbolName() {
        XCTAssertEqual(OutputType.Category.audio.symbolName, "waveform")
        XCTAssertEqual(OutputType.Category.video.symbolName, "film")
        XCTAssertEqual(OutputType.Category.image.symbolName, "photo")
        XCTAssertEqual(OutputType.Category.document.symbolName, "doc.richtext")
    }
}

final class ConversionJobMenuTitleTests: XCTestCase {
    let inputURL = URL(fileURLWithPath: "/tmp/test_video.mp4")
    let outputURL = URL(fileURLWithPath: "/tmp/test_video_converted.mkv")

    func makeJob(state: ConversionState, progress: Double = 0, etaSecondsRemaining: TimeInterval? = nil, isIndeterminate: Bool = false, errorMessage: String? = nil) -> ConversionJob {
        ConversionJob(id: UUID(), inputURL: inputURL, outputURL: outputURL, presetName: "MKV", state: state, progress: progress, etaSecondsRemaining: etaSecondsRemaining, isIndeterminate: isIndeterminate, errorMessage: errorMessage)
    }

    func test_queuedTitle() {
        let job = makeJob(state: .queued)
        XCTAssertEqual(job.menuTitle, "test_video.mp4 - Queued")
    }

    func test_runningTitle() {
        let job = makeJob(state: .running, progress: 42)
        XCTAssertEqual(job.menuTitle, "test_video.mp4 - 42%")
    }

    func test_runningTitle_indeterminate() {
        let job = makeJob(state: .running, progress: 0, isIndeterminate: true)
        XCTAssertEqual(job.menuTitle, "test_video.mp4 - Converting…")
    }

    func test_runningTitle_withETA() {
        let job = makeJob(state: .running, progress: 40, etaSecondsRemaining: 125)
        XCTAssertEqual(job.menuTitle, "test_video.mp4 - 40% (2m 5s left)")
    }

    func test_completedTitle() {
        let job = makeJob(state: .completed, progress: 100)
        XCTAssertEqual(job.menuTitle, "test_video.mp4 - Done")
    }

    func test_failedTitle() {
        let job = makeJob(state: .failed, errorMessage: "ffmpeg error: invalid file")
        XCTAssertEqual(job.menuTitle, "test_video.mp4 - Failed: ffmpeg error: invalid file")
    }

    func test_failedTitle_noMessage() {
        let job = makeJob(state: .failed)
        XCTAssertEqual(job.menuTitle, "test_video.mp4 - Failed")
    }

    func test_failedTitle_truncatedMessage() {
        let longMsg = String(repeating: "x", count: 100)
        let job = makeJob(state: .failed, errorMessage: longMsg)
        XCTAssertTrue(job.menuTitle.hasSuffix(" - Failed: \(String(repeating: "x", count: 40))"))
    }

    func test_cancelledTitle() {
        let job = makeJob(state: .cancelled)
        XCTAssertEqual(job.menuTitle, "test_video.mp4 - Cancelled")
    }

    func test_longFilenameTruncation() {
        let longName = String(repeating: "a", count: 50) + ".mp4"
        let url = URL(fileURLWithPath: "/tmp/\(longName)")
        let job = ConversionJob(id: UUID(), inputURL: url, outputURL: outputURL, presetName: "MP4", state: .queued, progress: 0, etaSecondsRemaining: nil, isIndeterminate: false, errorMessage: nil)
        XCTAssertTrue(job.menuTitle.count <= 50)
    }
}

final class ConversionStateSymbolTests: XCTestCase {
    func test_symbolNames() {
        XCTAssertEqual(ConversionState.queued.symbolName, "hourglass")
        XCTAssertEqual(ConversionState.running.symbolName, "arrow.triangle.2.circlepath")
        XCTAssertEqual(ConversionState.completed.symbolName, "checkmark.circle")
        XCTAssertEqual(ConversionState.failed.symbolName, "xmark.circle")
        XCTAssertEqual(ConversionState.cancelled.symbolName, "minus.circle")
    }
}

final class StringTruncationTests: XCTestCase {
    func test_shortString() {
        XCTAssertEqual("hello.txt".truncatedWithExtension(maxLength: 20), "hello.txt")
    }

    func test_exactFit() {
        XCTAssertEqual("12345678.txt".truncatedWithExtension(maxLength: 12), "12345678.txt")
    }

    func test_truncated() {
        let result = "abcdefghijklmnopqrstuvwxyz.txt".truncatedWithExtension(maxLength: 12)
        XCTAssertEqual(result.count, 12)
        XCTAssertTrue(result.hasSuffix(".txt"))
    }

    func test_noExtension() {
        let result = "hello".truncatedWithExtension(maxLength: 3)
        XCTAssertEqual(result.count, 3)
    }

    func test_empty() {
        XCTAssertEqual("".truncatedWithExtension(maxLength: 10), "")
    }
}
