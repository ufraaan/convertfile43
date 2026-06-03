import Foundation

enum FFconvService {
    static func buildArguments(outputType: OutputType, settings: ConversionSettings) -> [String] {
        var args: [String] = []

        args += ["--output-type", outputType.rawValue]

        if let quality = settings.quality {
            args += ["--quality", "\(Int(quality))"]
        }
        if let bitrate = settings.bitrate {
            args += ["--bitrate", bitrate]
        }
        if let sampleRate = settings.sampleRate {
            args += ["--sample-rate", "\(sampleRate)"]
        }
        if let channels = settings.channels {
            args += ["--channels", "\(channels)"]
        }
        if let scale = settings.scale {
            args += ["--scale", scale]
        }
        if let fps = settings.fps {
            args += ["--fps", "\(fps)"]
        }

        return args
    }
}
