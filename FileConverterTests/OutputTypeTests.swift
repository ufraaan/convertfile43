import XCTest
@testable import convertfile43

final class OutputTypeTests: XCTestCase {
    func test_allCases_areCovered() {
        let all = OutputType.allCases
        XCTAssertEqual(all.count, 18)
    }

    func test_category_audio() {
        let audioTypes: [OutputType] = [.aac, .flac, .mp3, .ogg, .wav]
        for type in audioTypes {
            XCTAssertEqual(type.category, .audio, "\(type) should be .audio")
        }
    }

    func test_category_video() {
        let videoTypes: [OutputType] = [.avi, .mkv, .mp4, .ogv, .webm]
        for type in videoTypes {
            XCTAssertEqual(type.category, .video, "\(type) should be .video")
        }
    }

    func test_category_image() {
        let imageTypes: [OutputType] = [.avif, .gif, .ico, .jpg, .png, .svg, .webp]
        for type in imageTypes {
            XCTAssertEqual(type.category, .image, "\(type) should be .image")
        }
    }

    func test_category_document() {
        XCTAssertEqual(OutputType.pdf.category, .document)
    }

    func test_fileExtension() {
        XCTAssertEqual(OutputType.jpg.fileExtension, "jpg")
        XCTAssertEqual(OutputType.mp4.fileExtension, "mp4")
        XCTAssertEqual(OutputType.mp3.fileExtension, "mp3")
        XCTAssertEqual(OutputType.png.fileExtension, "png")
        XCTAssertEqual(OutputType.pdf.fileExtension, "pdf")
        XCTAssertEqual(OutputType.svg.fileExtension, "svg")
    }

    func test_fileExtension_matchesRawValue_forMost() {
        let defaults: Set<OutputType> = [.jpg, .mp4, .mp3]
        for type in OutputType.allCases where !defaults.contains(type) {
            XCTAssertEqual(type.fileExtension, type.rawValue, "\(type) fileExtension should equal rawValue")
        }
    }

    func test_supportsQuality() {
        XCTAssertTrue(OutputType.jpg.supportsQuality)
        XCTAssertTrue(OutputType.webp.supportsQuality)
        XCTAssertTrue(OutputType.png.supportsQuality)
        XCTAssertTrue(OutputType.avif.supportsQuality)
        XCTAssertFalse(OutputType.mp4.supportsQuality)
        XCTAssertFalse(OutputType.mp3.supportsQuality)
        XCTAssertFalse(OutputType.pdf.supportsQuality)
    }

    func test_supportsBitrate() {
        XCTAssertTrue(OutputType.mp3.supportsBitrate)
        XCTAssertTrue(OutputType.aac.supportsBitrate)
        XCTAssertTrue(OutputType.ogg.supportsBitrate)
        XCTAssertFalse(OutputType.jpg.supportsBitrate)
        XCTAssertFalse(OutputType.mp4.supportsBitrate)
    }

    func test_supportsScale() {
        XCTAssertTrue(OutputType.jpg.supportsScale)
        XCTAssertTrue(OutputType.png.supportsScale)
        XCTAssertTrue(OutputType.webp.supportsScale)
        XCTAssertTrue(OutputType.avif.supportsScale)
        XCTAssertTrue(OutputType.gif.supportsScale)
        XCTAssertFalse(OutputType.mp4.supportsScale)
        XCTAssertFalse(OutputType.mp3.supportsScale)
    }

    func test_displayName() {
        XCTAssertEqual(OutputType.jpg.displayName, "JPG")
        XCTAssertEqual(OutputType.mp4.displayName, "MP4")
        XCTAssertEqual(OutputType.pdf.displayName, "PDF")
    }
}
