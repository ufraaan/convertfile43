import XCTest
@testable import convertfile43

final class ImageMagickServiceTests: XCTestCase {
    let input = "/path/to/input.png"
    let output = "/path/to/output.jpg"

    func test_buildArguments_minimal() {
        let settings = ConversionSettings()
        let args = ImageMagickService.buildArguments(input: input, output: output, settings: settings)
        XCTAssertEqual(args, [input, output])
    }

    func test_buildArguments_withQuality() {
        let settings = ConversionSettings(quality: 85)
        let args = ImageMagickService.buildArguments(input: input, output: output, settings: settings)
        XCTAssertEqual(args, [input, "-quality", "85", output])
    }

    func test_buildArguments_withScale() {
        let settings = ConversionSettings(scale: "800:600")
        let args = ImageMagickService.buildArguments(input: input, output: output, settings: settings)
        XCTAssertEqual(args, [input, "-resize", "800:600", output])
    }

    func test_buildArguments_withQualityAndScale() {
        let settings = ConversionSettings(quality: 90, scale: "1920:1080")
        let args = ImageMagickService.buildArguments(input: input, output: output, settings: settings)
        XCTAssertEqual(args, [input, "-quality", "90", "-resize", "1920:1080", output])
    }

    func test_buildArguments_outputIsLast() {
        let settings = ConversionSettings(quality: 75, scale: "1024:768")
        let args = ImageMagickService.buildArguments(input: input, output: output, settings: settings)
        XCTAssertEqual(args.last, output)
        XCTAssertEqual(args.first, input)
    }
}
