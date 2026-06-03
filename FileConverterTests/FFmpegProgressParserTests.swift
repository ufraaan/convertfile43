import XCTest
@testable import convertfile43

final class FFmpegProgressParserTests: XCTestCase {

    // MARK: - parseDuration

    func test_parseDuration_standardFormat() {
        let stderr = """
        Input #0, mov,mp4, from 'video.mp4':
          Duration: 00:01:30.50, start: 0.000000, bitrate: 1234 kb/s
        """
        guard let result = FFmpegProgressParser.parseDuration(from: stderr) else {
            XCTFail("Expected duration to be parsed")
            return
        }
        XCTAssertEqual(result, 90.5, accuracy: 0.001)
    }

    func test_parseDuration_tenMinutes() {
        let stderr = "Duration: 00:10:00.00"
        guard let result = FFmpegProgressParser.parseDuration(from: stderr) else {
            XCTFail("Expected duration to be parsed")
            return
        }
        XCTAssertEqual(result, 600.0, accuracy: 0.001)
    }

    func test_parseDuration_hoursFormat() {
        let stderr = "Duration: 01:23:45.67"
        guard let result = FFmpegProgressParser.parseDuration(from: stderr) else {
            XCTFail("Expected duration to be parsed")
            return
        }
        XCTAssertEqual(result, 3600 + 23 * 60 + 45.67, accuracy: 0.001)
    }

    func test_parseDuration_zeroDuration() {
        let stderr = "Duration: 00:00:00.00"
        guard let result = FFmpegProgressParser.parseDuration(from: stderr) else {
            XCTFail("Expected duration to be parsed")
            return
        }
        XCTAssertEqual(result, 0.0, accuracy: 0.001)
    }

    func test_parseDuration_missing() {
        let stderr = "No duration here"
        let result = FFmpegProgressParser.parseDuration(from: stderr)
        XCTAssertNil(result)
    }

    func test_parseDuration_empty() {
        let result = FFmpegProgressParser.parseDuration(from: "")
        XCTAssertNil(result)
    }

    // MARK: - parseTime

    func test_parseTime_findsLastLine() {
        let stderr = """
        frame=  100 fps=0.0 q=28.0 size=   0KiB time=00:00:01.00 bitrate=0.0kbits/s
        frame=  200 fps=0.0 q=28.0 size=   0KiB time=00:00:02.00 bitrate=0.0kbits/s
        frame=  300 fps=0.0 q=28.0 size=   0KiB time=00:00:05.50 bitrate=0.0kbits/s
        """
        guard let result = FFmpegProgressParser.parseTime(from: stderr) else {
            XCTFail("Expected time to be parsed")
            return
        }
        XCTAssertEqual(result, 5.5, accuracy: 0.001)
    }

    func test_parseTime_typicalFrame() {
        let stderr = "frame= 1800 fps=534 q=-0.0 size=46122KiB time=00:00:59.96 bitrate=6300.7kbits/s speed=17.9x"
        guard let result = FFmpegProgressParser.parseTime(from: stderr) else {
            XCTFail("Expected time to be parsed")
            return
        }
        XCTAssertEqual(result, 59.96, accuracy: 0.001)
    }

    func test_parseTime_zero() {
        let stderr = "time=00:00:00.00"
        guard let result = FFmpegProgressParser.parseTime(from: stderr) else {
            XCTFail("Expected time to be parsed")
            return
        }
        XCTAssertEqual(result, 0.0, accuracy: 0.001)
    }

    func test_parseTime_missing() {
        let stderr = "no time here"
        let result = FFmpegProgressParser.parseTime(from: stderr)
        XCTAssertNil(result)
    }

    // MARK: - parseSpeed

    func test_parseSpeed_decimal() {
        let stderr = "frame= 1800 fps=534 q=-0.0 time=00:00:59.96 speed=17.9x"
        guard let result = FFmpegProgressParser.parseSpeed(from: stderr) else {
            XCTFail("Expected speed to be parsed")
            return
        }
        XCTAssertEqual(result, 17.9, accuracy: 0.001)
    }

    func test_parseSpeed_integer() {
        let stderr = "speed=5x"
        guard let result = FFmpegProgressParser.parseSpeed(from: stderr) else {
            XCTFail("Expected speed to be parsed")
            return
        }
        XCTAssertEqual(result, 5.0, accuracy: 0.001)
    }

    func test_parseSpeed_findsLastLine() {
        let stderr = """
        speed=1.0x
        speed=2.5x
        speed=10.7x
        """
        guard let result = FFmpegProgressParser.parseSpeed(from: stderr) else {
            XCTFail("Expected speed to be parsed")
            return
        }
        XCTAssertEqual(result, 10.7, accuracy: 0.001)
    }

    func test_parseSpeed_missing() {
        let stderr = "no speed"
        let result = FFmpegProgressParser.parseSpeed(from: stderr)
        XCTAssertNil(result)
    }

    // MARK: - progress

    func test_progress_50Percent() {
        let stderr = """
          Duration: 00:00:10.00, start: 0.000000, bitrate: 0 kb/s
        frame= 150 fps=30 q=28.0 time=00:00:05.00 speed=2.0x
        """
        let result = FFmpegProgressParser.progress(from: stderr)
        XCTAssertEqual(result, 50.0, accuracy: 0.001)
    }

    func test_progress_100Percent() {
        let stderr = """
          Duration: 00:00:10.00, start: 0.000000, bitrate: 0 kb/s
        frame= 300 fps=30 q=28.0 time=00:00:10.00 speed=2.0x
        """
        let result = FFmpegProgressParser.progress(from: stderr)
        XCTAssertEqual(result, 100.0, accuracy: 0.001)
    }

    func test_progress_99Percent() {
        let stderr = """
          Duration: 00:00:10.00, start: 0.000000
        time=00:00:09.99
        """
        let result = FFmpegProgressParser.progress(from: stderr)
        XCTAssertEqual(result, 99.9, accuracy: 0.001)
    }

    func test_progress_clampsAbove100() {
        let stderr = """
          Duration: 00:00:10.00
        time=00:00:15.00
        """
        let result = FFmpegProgressParser.progress(from: stderr)
        XCTAssertEqual(result, 100.0, accuracy: 0.001)
    }

    func test_progress_returnsMinusOneIfNoDuration() {
        let stderr = "time=00:00:05.00"
        let result = FFmpegProgressParser.progress(from: stderr)
        XCTAssertEqual(result, -1)
    }

    func test_progress_returnsMinusOneIfNoTime() {
        let stderr = "Duration: 00:00:10.00"
        let result = FFmpegProgressParser.progress(from: stderr)
        XCTAssertEqual(result, -1)
    }

    func test_progress_returnsMinusOneForEmpty() {
        let result = FFmpegProgressParser.progress(from: "")
        XCTAssertEqual(result, -1)
    }

    func test_estimatedSecondsRemaining_halfDoneAt2x() {
        let stderr = """
          Duration: 00:00:10.00
        time=00:00:05.00 speed=2.0x
        """
        guard let eta = FFmpegProgressParser.estimatedSecondsRemaining(from: stderr) else {
            XCTFail("Expected ETA")
            return
        }
        XCTAssertEqual(eta, 2.5, accuracy: 0.01)
    }

    func test_snapshot_includesETA() {
        let stderr = """
          Duration: 00:01:00.00
        time=00:00:30.00 speed=1.5x
        """
        guard let snap = FFmpegProgressParser.snapshot(from: stderr) else {
            XCTFail("Expected snapshot")
            return
        }
        XCTAssertEqual(snap.percent, 50, accuracy: 0.1)
        XCTAssertEqual(snap.etaSeconds ?? 0, 20, accuracy: 0.5)
    }

    func test_progress_realisticFfmpegOutput() {
        let stderr = """
        ffmpeg version n6.0
        Input #0, lavfi, from 'testsrc2=duration=30:size=1280x720:rate=30':
          Duration: 00:00:30.00, start: 0.000000, bitrate: 0 kb/s
          Stream #0:0: Video: rawvideo (RGB[24] / 0x42475200), rgb24, 1280x720, 30 fps
        Stream mapping:
          Stream #0:0 -> #0:0 (rawvideo (native) -> h264 (libx264))
        Press [q] to stop, [?] for help
        frame=  150 fps=0.0 q=28.0 size=       0kB time=00:00:01.00 bitrate=   0.0kbits/s speed=0.919x
        frame=  900 fps=450 q=28.0 size=     256kB time=00:00:15.00 bitrate= 139.8kbits/s speed=15.0x
        frame= 1800 fps=534 q=28.0 size=    1024kB time=00:00:30.00 bitrate= 279.6kbits/s speed=17.9x
        """
        let result = FFmpegProgressParser.progress(from: stderr)
        XCTAssertEqual(result, 100.0, accuracy: 0.001)
    }
}
