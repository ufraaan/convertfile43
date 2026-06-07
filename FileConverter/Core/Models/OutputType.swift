import Foundation

enum OutputType: String, Codable, CaseIterable, Sendable {
    case aac, avi, avif, flac, gif, ico, jpg, mov, mp3, mp4, mkv, ogg, ogv, pdf, png, svg, wav, webm, webp

    var displayName: String {
        rawValue.uppercased()
    }

    var fileExtension: String {
        switch self {
        case .jpg: return "jpg"
        case .mp4: return "mp4"
        case .mp3: return "mp3"
        default: return rawValue
        }
    }

    var category: Category {
        switch self {
        case .aac, .flac, .mp3, .ogg, .wav: return .audio
        case .avi, .mkv, .mov, .mp4, .ogv, .webm: return .video
        case .avif, .gif, .ico, .jpg, .png, .svg, .webp: return .image
        case .pdf: return .document
        }
    }

    enum Category: String, Codable, Sendable {
        case audio, video, image, document
    }

    var supportsQuality: Bool {
        switch self {
        case .jpg, .webp, .png, .avif: return true
        default: return false
        }
    }

    var supportsBitrate: Bool {
        switch self {
        case .mp3, .aac, .ogg, .flac, .wav: return true
        default: return false
        }
    }

    var supportsScale: Bool {
        switch self {
        case .jpg, .png, .webp, .avif, .gif: return true
        default: return false
        }
    }
}
