import Foundation

enum ImageMagickService {
    static func buildArguments(input: String, output: String, settings: ConversionSettings) -> [String] {
        var args: [String] = []

        args.append(input)

        if let quality = settings.quality {
            args.append(contentsOf: ["-quality", "\(quality)"])
        }

        if let scale = settings.scale {
            args.append(contentsOf: ["-resize", scale])
        }

        args.append(output)
        return args
    }

    static func isSVGInput(_ input: String) -> Bool {
        input.lowercased().hasSuffix(".svg")
    }

    static func isSVGOutput(_ output: String) -> Bool {
        output.lowercased().hasSuffix(".svg")
    }
}
