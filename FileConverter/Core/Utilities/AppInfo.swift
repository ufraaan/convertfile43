import Foundation

enum AppInfo {
    static var shortVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    static var isFFmpegBundled: Bool {
        Bundle.main.path(forResource: "ffmpeg", ofType: nil) != nil
    }

    static var isFFconvBundled: Bool {
        BundlePaths.isFFConvAvailable
    }
}
