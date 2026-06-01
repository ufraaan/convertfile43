import Foundation

struct ConversionPreset: Identifiable, Codable, Sendable {
    var id: UUID
    var name: String
    var inputExtensions: [String]
    var outputType: OutputType
    var settings: ConversionSettings
    var isBuiltIn: Bool

    init(
        id: UUID = UUID(),
        name: String,
        inputExtensions: [String],
        outputType: OutputType,
        settings: ConversionSettings = .default,
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.inputExtensions = inputExtensions
        self.outputType = outputType
        self.settings = settings
        self.isBuiltIn = isBuiltIn
    }

    static let defaultPresets: [ConversionPreset] = [
        ConversionPreset(
            name: "MP3 320kbps",
            inputExtensions: ["mp3", "wav", "flac", "ogg", "m4a", "wma", "aac"],
            outputType: .mp3,
            settings: ConversionSettings(quality: nil, bitrate: "320k", sampleRate: 44100, channels: 2, scale: nil, fps: nil, encodingSpeed: nil),
            isBuiltIn: true
        ),
        ConversionPreset(
            name: "AAC 256kbps",
            inputExtensions: ["mp3", "wav", "flac", "ogg", "m4a", "wma", "aac"],
            outputType: .aac,
            settings: ConversionSettings(quality: nil, bitrate: "256k", sampleRate: 44100, channels: 2, scale: nil, fps: nil, encodingSpeed: nil),
            isBuiltIn: true
        ),
        ConversionPreset(
            name: "FLAC Lossless",
            inputExtensions: ["mp3", "wav", "flac", "ogg", "m4a", "wma", "aac"],
            outputType: .flac,
            settings: ConversionSettings(quality: nil, bitrate: nil, sampleRate: 48000, channels: 2, scale: nil, fps: nil, encodingSpeed: nil),
            isBuiltIn: true
        ),
        ConversionPreset(
            name: "MP4 1080p",
            inputExtensions: ["mp4", "mkv", "avi", "mov", "webm", "ogv", "wmv", "flv"],
            outputType: .mp4,
            settings: ConversionSettings(quality: nil, bitrate: nil, sampleRate: nil, channels: nil, scale: "1920:1080", fps: 30, encodingSpeed: "medium"),
            isBuiltIn: true
        ),
        ConversionPreset(
            name: "MP4 720p",
            inputExtensions: ["mp4", "mkv", "avi", "mov", "webm", "ogv", "wmv", "flv"],
            outputType: .mp4,
            settings: ConversionSettings(quality: nil, bitrate: nil, sampleRate: nil, channels: nil, scale: "1280:720", fps: 30, encodingSpeed: "medium"),
            isBuiltIn: true
        ),
        ConversionPreset(
            name: "MKV 1080p",
            inputExtensions: ["mp4", "mkv", "avi", "mov", "webm", "ogv", "wmv", "flv"],
            outputType: .mkv,
            settings: ConversionSettings(quality: nil, bitrate: nil, sampleRate: nil, channels: nil, scale: "1920:1080", fps: 30, encodingSpeed: "medium"),
            isBuiltIn: true
        ),
        ConversionPreset(
            name: "WebM VP9",
            inputExtensions: ["mp4", "mkv", "avi", "mov", "webm", "ogv", "wmv", "flv"],
            outputType: .webm,
            settings: ConversionSettings(quality: nil, bitrate: nil, sampleRate: nil, channels: nil, scale: "1280:720", fps: 30, encodingSpeed: "medium"),
            isBuiltIn: true
        ),
        ConversionPreset(
            name: "JPEG High Quality",
            inputExtensions: ["jpg", "jpeg", "png", "webp", "avif", "bmp", "tiff", "tif", "gif"],
            outputType: .jpg,
            settings: ConversionSettings(quality: 90, bitrate: nil, sampleRate: nil, channels: nil, scale: nil, fps: nil, encodingSpeed: nil),
            isBuiltIn: true
        ),
        ConversionPreset(
            name: "PNG Lossless",
            inputExtensions: ["jpg", "jpeg", "png", "webp", "avif", "bmp", "tiff", "tif", "gif"],
            outputType: .png,
            settings: ConversionSettings(quality: nil, bitrate: nil, sampleRate: nil, channels: nil, scale: nil, fps: nil, encodingSpeed: nil),
            isBuiltIn: true
        ),
        ConversionPreset(
            name: "WebP",
            inputExtensions: ["jpg", "jpeg", "png", "webp", "avif", "bmp", "tiff", "tif", "gif"],
            outputType: .webp,
            settings: ConversionSettings(quality: 80, bitrate: nil, sampleRate: nil, channels: nil, scale: nil, fps: nil, encodingSpeed: nil),
            isBuiltIn: true
        ),
        ConversionPreset(
            name: "Animated GIF",
            inputExtensions: ["mp4", "mkv", "avi", "mov", "webm", "gif"],
            outputType: .gif,
            settings: ConversionSettings(quality: nil, bitrate: nil, sampleRate: nil, channels: nil, scale: "800:-1", fps: 15, encodingSpeed: nil),
            isBuiltIn: true
        ),
        ConversionPreset(
            name: "PDF (Images)",
            inputExtensions: ["jpg", "jpeg", "png", "webp", "bmp", "tiff"],
            outputType: .pdf,
            settings: ConversionSettings(quality: 90, bitrate: nil, sampleRate: nil, channels: nil, scale: nil, fps: nil, encodingSpeed: nil),
            isBuiltIn: true
        ),
        ConversionPreset(
            name: "ICO 256x256",
            inputExtensions: ["jpg", "jpeg", "png", "webp", "bmp", "gif"],
            outputType: .ico,
            settings: ConversionSettings(quality: nil, bitrate: nil, sampleRate: nil, channels: nil, scale: "256:256", fps: nil, encodingSpeed: nil),
            isBuiltIn: true
        ),
    ]
}
