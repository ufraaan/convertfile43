import Foundation

struct ConversionSettings: Codable, Sendable {
    var quality: Double?
    var bitrate: String?
    var sampleRate: Int?
    var channels: Int?
    var scale: String?
    var fps: Int?
    var encodingSpeed: String?

    static let `default` = ConversionSettings(
        quality: 80,
        bitrate: nil,
        sampleRate: nil,
        channels: nil,
        scale: nil,
        fps: nil,
        encodingSpeed: nil
    )
}
