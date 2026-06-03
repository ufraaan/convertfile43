import Foundation

enum FFmpegService {
    static func buildArguments(input: String, output: String, settings: ConversionSettings, outputType: OutputType) -> [String] {
        var args: [String] = []

        args.append(contentsOf: ["-i", input, "-y"])

        args.append("-nostdin")

        switch outputType {
        case .mp3:
            args.append(contentsOf: ["-codec:a", "libmp3lame"])
            if let bitrate = settings.bitrate {
                args.append(contentsOf: ["-b:a", bitrate])
            }
        case .aac:
            args.append(contentsOf: ["-codec:a", "aac"])
            if let bitrate = settings.bitrate {
                args.append(contentsOf: ["-b:a", bitrate])
            }
        case .flac:
            args.append(contentsOf: ["-codec:a", "flac"])
        case .ogg:
            args.append(contentsOf: ["-codec:a", "libvorbis"])
            if let bitrate = settings.bitrate {
                args.append(contentsOf: ["-b:a", bitrate])
            }
        case .wav:
            args.append(contentsOf: ["-codec:a", "pcm_s16le"])
        case .mp4:
            args.append(contentsOf: ["-codec:v", "h264_videotoolbox", "-codec:a", "aac"])
            if let scale = settings.scale {
                args.append(contentsOf: ["-vf", "scale=\(scale)"])
            }
            if let fps = settings.fps {
                args.append(contentsOf: ["-r", "\(fps)"])
            }
        case .mkv:
            args.append(contentsOf: ["-codec:v", "h264_videotoolbox", "-codec:a", "aac"])
            if let scale = settings.scale {
                args.append(contentsOf: ["-vf", "scale=\(scale)"])
            }
            if let fps = settings.fps {
                args.append(contentsOf: ["-r", "\(fps)"])
            }
        case .avi:
            args.append(contentsOf: ["-codec:v", "h264_videotoolbox", "-codec:a", "aac"])
        case .webm:
            args.append(contentsOf: ["-codec:v", "libvpx-vp9", "-codec:a", "libopus"])
            if let scale = settings.scale {
                args.append(contentsOf: ["-vf", "scale=\(scale)"])
            }
        case .ogv:
            args.append(contentsOf: ["-codec:v", "libtheora", "-codec:a", "libvorbis"])
        case .gif:
            args.append(contentsOf: ["-vf", "fps=\(settings.fps ?? 15),scale=\(settings.scale ?? "800:-1"):flags=lanczos"])
        case .jpg:
            args.append(contentsOf: ["-frames:v", "1", "-codec:v", "mjpeg"])
            if let quality = settings.quality {
                let q = max(2, min(31, 31 - Int((quality / 100.0) * 29.0)))
                args.append(contentsOf: ["-q:v", "\(q)"])
            }
            if let scale = settings.scale {
                args.append(contentsOf: ["-vf", "scale=\(scale)"])
            }
        case .png:
            args.append(contentsOf: ["-frames:v", "1", "-codec:v", "png"])
            if settings.quality != nil {
                let level = max(1, min(9, Int((settings.quality ?? 80) / 11)))
                args.append(contentsOf: ["-compression_level", "\(level)"])
            }
            if let scale = settings.scale {
                args.append(contentsOf: ["-vf", "scale=\(scale)"])
            }
        case .webp:
            args.append(contentsOf: ["-frames:v", "1", "-codec:v", "libwebp"])
            if let quality = settings.quality {
                args.append(contentsOf: ["-q:v", "\(Int(quality))"])
            }
            if let scale = settings.scale {
                args.append(contentsOf: ["-vf", "scale=\(scale)"])
            }
        case .avif:
            args.append(contentsOf: ["-frames:v", "1", "-codec:v", "libaom-av1"])
            if let quality = settings.quality {
                args.append(contentsOf: ["-q:v", "\(Int(quality))"])
            }
            if let scale = settings.scale {
                args.append(contentsOf: ["-vf", "scale=\(scale)"])
            }
        case .ico:
            args.append(contentsOf: ["-frames:v", "1"])
            if let scale = settings.scale {
                args.append(contentsOf: ["-vf", "scale=\(scale)"])
            }
        case .pdf:
            args.append(contentsOf: ["-frames:v", "1"])
            if let scale = settings.scale {
                args.append(contentsOf: ["-vf", "scale=\(scale)"])
            }
        case .svg:
            break
        }

        if outputType.category == .audio || outputType.category == .video {
            if let sampleRate = settings.sampleRate {
                args.append(contentsOf: ["-ar", "\(sampleRate)"])
            }
            if let channels = settings.channels {
                args.append(contentsOf: ["-ac", "\(channels)"])
            }
        }

        if (outputType.category == .image && outputType != .gif) || outputType == .pdf {
            args.append("-update")
            args.append("1")
        }

        args.append(output)
        return args
    }
}
