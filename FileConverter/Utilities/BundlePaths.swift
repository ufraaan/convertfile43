import Foundation

enum BundlePaths {
    static var ffmpeg: String {
        bundlePath("ffmpeg")
    }

    static var imagemagick: String {
        bundlePath("magick")
    }

    static var ghostscript: String {
        bundlePath("gs")
    }

    private static func bundlePath(_ executable: String) -> String {
        Bundle.main.path(forResource: executable, ofType: nil)
            ?? "/usr/local/bin/\(executable)"
    }
}
