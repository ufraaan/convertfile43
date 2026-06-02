import XCTest
@testable import convertfile43

final class FFmpegServiceTests: XCTestCase {
    let input = "/path/to/input.mp4"
    let output = "/path/to/output.mp3"

    func test_buildArguments_mp3() {
        let settings = ConversionSettings(quality: nil, bitrate: "320k", sampleRate: 44100, channels: 2, scale: nil, fps: nil, encodingSpeed: nil)
        let args = FFmpegService.buildArguments(input: input, output: output, settings: settings, outputType: .mp3)
        XCTAssertEqual(args, ["-i", input, "-y", "-nostdin", "-codec:a", "libmp3lame", "-b:a", "320k", "-ar", "44100", "-ac", "2", output])
    }

    func test_buildArguments_mp4_withScale() {
        let settings = ConversionSettings(quality: nil, bitrate: nil, sampleRate: nil, channels: nil, scale: "1920:1080", fps: 30, encodingSpeed: "medium")
        let args = FFmpegService.buildArguments(input: input, output: "/path/to/output.mp4", settings: settings, outputType: .mp4)
        XCTAssertEqual(args, ["-i", input, "-y", "-nostdin", "-codec:v", "h264_videotoolbox", "-codec:a", "aac", "-vf", "scale=1920:1080", "-r", "30", "/path/to/output.mp4"])
    }

    func test_buildArguments_mp4_noSettings() {
        let settings = ConversionSettings()
        let args = FFmpegService.buildArguments(input: input, output: "/path/to/output.mp4", settings: settings, outputType: .mp4)
        XCTAssertEqual(args, ["-i", input, "-y", "-nostdin", "-codec:v", "h264_videotoolbox", "-codec:a", "aac", "/path/to/output.mp4"])
    }

    func test_buildArguments_aac() {
        let settings = ConversionSettings(quality: nil, bitrate: "256k", sampleRate: nil, channels: nil, scale: nil, fps: nil, encodingSpeed: nil)
        let args = FFmpegService.buildArguments(input: input, output: "/path/to/output.aac", settings: settings, outputType: .aac)
        XCTAssertEqual(args, ["-i", input, "-y", "-nostdin", "-codec:a", "aac", "-b:a", "256k", "/path/to/output.aac"])
    }

    func test_buildArguments_flac() {
        let settings = ConversionSettings()
        let args = FFmpegService.buildArguments(input: input, output: "/path/to/output.flac", settings: settings, outputType: .flac)
        XCTAssertEqual(args, ["-i", input, "-y", "-nostdin", "-codec:a", "flac", "/path/to/output.flac"])
    }

    func test_buildArguments_gif() {
        let settings = ConversionSettings(quality: nil, bitrate: nil, sampleRate: nil, channels: nil, scale: "800:-1", fps: 15, encodingSpeed: nil)
        let args = FFmpegService.buildArguments(input: input, output: "/path/to/output.gif", settings: settings, outputType: .gif)
        XCTAssertEqual(args, ["-i", input, "-y", "-nostdin", "-vf", "fps=15,scale=800:-1:flags=lanczos", "/path/to/output.gif"])
    }

    func test_buildArguments_webm() {
        let settings = ConversionSettings(scale: "1280:720")
        let args = FFmpegService.buildArguments(input: input, output: "/path/to/output.webm", settings: settings, outputType: .webm)
        XCTAssertEqual(args, ["-i", input, "-y", "-nostdin", "-codec:v", "libvpx-vp9", "-codec:a", "libopus", "-vf", "scale=1280:720", "/path/to/output.webm"])
    }

    func test_buildArguments_mkv() {
        let settings = ConversionSettings()
        let args = FFmpegService.buildArguments(input: input, output: "/path/to/output.mkv", settings: settings, outputType: .mkv)
        XCTAssertEqual(args, ["-i", input, "-y", "-nostdin", "-codec:v", "h264_videotoolbox", "-codec:a", "aac", "/path/to/output.mkv"])
    }

    func test_buildArguments_outputIsLast() {
        let settings = ConversionSettings(bitrate: "320k", sampleRate: 44100, channels: 2, scale: "1280:720", fps: 30, encodingSpeed: "fast")
        let args = FFmpegService.buildArguments(input: input, output: output, settings: settings, outputType: .mp3)
        XCTAssertEqual(args.last, output)
    }

    // MARK: - Image conversions

    func test_buildArguments_jpg() {
        let imageInput = "/path/to/input.png"
        let imageOutput = "/path/to/output.jpg"
        let settings = ConversionSettings(quality: 90, scale: "1920:1080")
        let args = FFmpegService.buildArguments(input: imageInput, output: imageOutput, settings: settings, outputType: .jpg)
        XCTAssertEqual(args, ["-i", imageInput, "-y", "-nostdin", "-frames:v", "1", "-codec:v", "mjpeg", "-q:v", "5", "-vf", "scale=1920:1080", "-update", "1", imageOutput])
    }

    func test_buildArguments_jpg_noSettings() {
        let imageInput = "/path/to/input.png"
        let imageOutput = "/path/to/output.jpg"
        let settings = ConversionSettings()
        let args = FFmpegService.buildArguments(input: imageInput, output: imageOutput, settings: settings, outputType: .jpg)
        XCTAssertEqual(args, ["-i", imageInput, "-y", "-nostdin", "-frames:v", "1", "-codec:v", "mjpeg", "-update", "1", imageOutput])
    }

    func test_buildArguments_png() {
        let imageInput = "/path/to/input.jpg"
        let imageOutput = "/path/to/output.png"
        let settings = ConversionSettings(quality: 80)
        let args = FFmpegService.buildArguments(input: imageInput, output: imageOutput, settings: settings, outputType: .png)
        XCTAssertEqual(args, ["-i", imageInput, "-y", "-nostdin", "-frames:v", "1", "-codec:v", "png", "-compression_level", "7", "-update", "1", imageOutput])
    }

    func test_buildArguments_webp() {
        let imageInput = "/path/to/input.png"
        let imageOutput = "/path/to/output.webp"
        let settings = ConversionSettings(quality: 80, scale: "800:600")
        let args = FFmpegService.buildArguments(input: imageInput, output: imageOutput, settings: settings, outputType: .webp)
        XCTAssertEqual(args, ["-i", imageInput, "-y", "-nostdin", "-frames:v", "1", "-codec:v", "libwebp", "-q:v", "80", "-vf", "scale=800:600", "-update", "1", imageOutput])
    }

    func test_buildArguments_ico_withScale() {
        let imageInput = "/path/to/input.png"
        let imageOutput = "/path/to/output.ico"
        let settings = ConversionSettings(scale: "256:256")
        let args = FFmpegService.buildArguments(input: imageInput, output: imageOutput, settings: settings, outputType: .ico)
        XCTAssertEqual(args, ["-i", imageInput, "-y", "-nostdin", "-frames:v", "1", "-vf", "scale=256:256", "-update", "1", imageOutput])
    }

    func test_buildArguments_pdf() {
        let imageInput = "/path/to/input.png"
        let imageOutput = "/path/to/output.pdf"
        let settings = ConversionSettings()
        let args = FFmpegService.buildArguments(input: imageInput, output: imageOutput, settings: settings, outputType: .pdf)
        XCTAssertEqual(args, ["-i", imageInput, "-y", "-nostdin", "-frames:v", "1", "-update", "1", imageOutput])
    }

    func test_buildArguments_imageOutputIsLast() {
        let imageInput = "/path/to/input.png"
        let imageOutput = "/path/to/output.jpg"
        let settings = ConversionSettings(quality: 90)
        let args = FFmpegService.buildArguments(input: imageInput, output: imageOutput, settings: settings, outputType: .jpg)
        XCTAssertEqual(args.last, imageOutput)
    }

    func test_buildArguments_jpgQualityMapping() {
        let imageInput = "/path/to/input.png"
        let imageOutput = "/path/to/output.jpg"
        // quality 100 -> q:v 2
        let settings100 = ConversionSettings(quality: 100)
        let args100 = FFmpegService.buildArguments(input: imageInput, output: imageOutput, settings: settings100, outputType: .jpg)
        XCTAssertEqual(args100, ["-i", imageInput, "-y", "-nostdin", "-frames:v", "1", "-codec:v", "mjpeg", "-q:v", "2", "-update", "1", imageOutput])

        // quality 1 -> q:v 31
        let settings1 = ConversionSettings(quality: 1)
        let args1 = FFmpegService.buildArguments(input: imageInput, output: imageOutput, settings: settings1, outputType: .jpg)
        XCTAssertEqual(args1, ["-i", imageInput, "-y", "-nostdin", "-frames:v", "1", "-codec:v", "mjpeg", "-q:v", "31", "-update", "1", imageOutput])
    }
}
