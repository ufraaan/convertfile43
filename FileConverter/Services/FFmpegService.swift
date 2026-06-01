import Foundation

enum FFmpegService {
    static func buildArguments(input: String, output: String, settings: ConversionSettings, outputType: OutputType) -> [String] {
        var args: [String] = []

        args.append(contentsOf: ["-i", input, "-y"])

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
            args.append(contentsOf: ["-codec:v", "libx264", "-codec:a", "aac"])
            if let scale = settings.scale {
                args.append(contentsOf: ["-vf", "scale=\(scale)"])
            }
            if let fps = settings.fps {
                args.append(contentsOf: ["-r", "\(fps)"])
            }
            if let speed = settings.encodingSpeed {
                args.append(contentsOf: ["-preset", speed])
            }
        case .mkv:
            args.append(contentsOf: ["-codec:v", "libx264", "-codec:a", "aac"])
            if let scale = settings.scale {
                args.append(contentsOf: ["-vf", "scale=\(scale)"])
            }
            if let fps = settings.fps {
                args.append(contentsOf: ["-r", "\(fps)"])
            }
        case .avi:
            args.append(contentsOf: ["-codec:v", "libx264", "-codec:a", "aac"])
        case .webm:
            args.append(contentsOf: ["-codec:v", "libvpx-vp9", "-codec:a", "libopus"])
            if let scale = settings.scale {
                args.append(contentsOf: ["-vf", "scale=\(scale)"])
            }
        case .ogv:
            args.append(contentsOf: ["-codec:v", "libtheora", "-codec:a", "libvorbis"])
        case .gif:
            args.append(contentsOf: ["-vf", "fps=\(settings.fps ?? 15),scale=\(settings.scale ?? "800:-1"):flags=lanczos"])
        default:
            break
        }

        if let sampleRate = settings.sampleRate {
            args.append(contentsOf: ["-ar", "\(sampleRate)"])
        }

        if let channels = settings.channels {
            args.append(contentsOf: ["-ac", "\(channels)"])
        }

        args.append(output)
        return args
    }
}
