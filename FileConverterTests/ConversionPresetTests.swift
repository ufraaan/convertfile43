import XCTest
@testable import convertfile43

final class ConversionPresetTests: XCTestCase {
    func test_defaultPresets_count() {
        let presets = ConversionPreset.defaultPresets
        XCTAssertEqual(presets.count, 14)
    }

    func test_defaultPresets_allAreBuiltIn() {
        for preset in ConversionPreset.defaultPresets {
            XCTAssertTrue(preset.isBuiltIn, "\(preset.name) should be built-in")
        }
    }

    func test_defaultPresets_haveUniqueNames() {
        let names = ConversionPreset.defaultPresets.map(\.name)
        let uniqueNames = Set(names)
        XCTAssertEqual(names.count, uniqueNames.count)
    }

    func test_defaultPresets_haveValidOutputTypes() {
        for preset in ConversionPreset.defaultPresets {
            XCTAssertTrue(OutputType.allCases.contains(preset.outputType), "\(preset.name) has invalid output type")
        }
    }

    func test_defaultPresets_haveNonEmptyInputExtensions() {
        for preset in ConversionPreset.defaultPresets {
            XCTAssertFalse(preset.inputExtensions.isEmpty, "\(preset.name) should have input extensions")
        }
    }

    func test_defaultPresets_audioPresetsHaveAudioOutputType() {
        let audioPresets = ConversionPreset.defaultPresets.filter { $0.outputType.category == .audio }
        XCTAssertFalse(audioPresets.isEmpty)
        for preset in audioPresets {
            XCTAssertEqual(preset.outputType.category, .audio)
        }
    }

    func test_defaultPresets_videoPresetsHaveVideoOutputType() {
        let videoPresets = ConversionPreset.defaultPresets.filter { $0.outputType.category == .video }
        XCTAssertFalse(videoPresets.isEmpty)
        for preset in videoPresets {
            XCTAssertEqual(preset.outputType.category, .video)
        }
    }

    func test_mp3Preset_hasCorrectBitrate() {
        let mp3 = ConversionPreset.defaultPresets.first { $0.name == "MP3 320kbps" }
        XCTAssertNotNil(mp3)
        XCTAssertEqual(mp3?.settings.bitrate, "320k")
    }

    func test_mp4Preset_hasNoScale() {
        let mp4 = ConversionPreset.defaultPresets.first { $0.name == "MP4" }
        XCTAssertNotNil(mp4)
        XCTAssertNil(mp4?.settings.scale)
    }

    func test_aviPreset_exists() {
        let avi = ConversionPreset.defaultPresets.first { $0.name == "AVI" }
        XCTAssertNotNil(avi)
        XCTAssertEqual(avi?.outputType, .avi)
    }

    func test_jpegPreset_hasCorrectQuality() {
        let jpeg = ConversionPreset.defaultPresets.first { $0.name == "JPEG High Quality" }
        XCTAssertNotNil(jpeg)
        XCTAssertEqual(jpeg?.settings.quality, 90)
    }

    func test_gifPreset_hasCorrectFps() {
        let gif = ConversionPreset.defaultPresets.first { $0.name == "Animated GIF" }
        XCTAssertNotNil(gif)
        XCTAssertEqual(gif?.settings.fps, 15)
    }
}
