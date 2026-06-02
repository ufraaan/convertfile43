import XCTest
@testable import convertfile43

final class GhostscriptServiceTests: XCTestCase {
    func test_buildPDFToImageArguments() {
        let args = GhostscriptService.buildPDFToImageArguments(input: "/path/to/input.pdf", output: "/path/to/output.png")
        XCTAssertEqual(args, ["-dNOPAUSE", "-dBATCH", "-sDEVICE=png16m", "-r150", "-sOutputFile=/path/to/output.png", "/path/to/input.pdf"])
    }

    func test_buildPDFToImageArguments_customResolution() {
        let args = GhostscriptService.buildPDFToImageArguments(input: "/path/to/input.pdf", output: "/path/to/output.png", resolution: 300)
        XCTAssertEqual(args, ["-dNOPAUSE", "-dBATCH", "-sDEVICE=png16m", "-r300", "-sOutputFile=/path/to/output.png", "/path/to/input.pdf"])
    }

    func test_buildImageToPDFArguments() {
        let args = GhostscriptService.buildImageToPDFArguments(input: "/path/to/input.png", output: "/path/to/output.pdf")
        XCTAssertEqual(args, ["-dNOPAUSE", "-dBATCH", "-sDEVICE=pdfwrite", "-sOutputFile=/path/to/output.pdf", "/path/to/input.png"])
    }
}
