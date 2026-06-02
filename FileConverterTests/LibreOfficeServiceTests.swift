import XCTest
@testable import convertfile43

final class LibreOfficeServiceTests: XCTestCase {
    func test_buildConvertToPDFArguments() {
        let args = LibreOfficeService.buildConvertToPDFArguments(input: "/path/to/document.docx", outputDir: "/path/to")
        XCTAssertEqual(args, ["--headless", "--convert-to", "pdf", "--outdir", "/path/to", "/path/to/document.docx"])
    }

    func test_buildConvertToPDFArguments_outputDirMatchesInputDir() {
        let input = "/Users/test/Documents/report.docx"
        let outputDir = "/Users/test/Documents"
        let args = LibreOfficeService.buildConvertToPDFArguments(input: input, outputDir: outputDir)
        XCTAssertTrue(args.contains(input))
        XCTAssertTrue(args.contains(outputDir))
    }
}
