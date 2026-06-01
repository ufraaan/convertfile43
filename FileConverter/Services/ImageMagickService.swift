import Foundation

enum ImageMagickService {
    static func buildArguments(input: String, output: String, settings: ConversionSettings) -> [String] {
        var args: [String] = [input]

        if let quality = settings.quality {
            args.append(contentsOf: ["-quality", "\(Int(quality))"])
        }

        if let scale = settings.scale {
            args.append(contentsOf: ["-resize", scale])
        }

        args.append(output)
        return args
    }
}
