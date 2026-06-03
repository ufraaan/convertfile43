import Foundation

struct ConversionJob: Identifiable, Sendable {
    let id: UUID
    let inputURL: URL
    let outputURL: URL
    let presetName: String
    var state: ConversionState
    var progress: Double
    /// Wall-clock seconds remaining when ffmpeg reports speed= (nil if unknown).
    var etaSecondsRemaining: TimeInterval?
    /// True when percent is unknown (ImageMagick, LibreOffice, etc.).
    var isIndeterminate: Bool
    var errorMessage: String?

    var fileName: String {
        inputURL.lastPathComponent
    }

    var outputFileName: String {
        outputURL.lastPathComponent
    }
}
