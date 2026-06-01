import Foundation

struct ConversionJob: Identifiable, Sendable {
    let id: UUID
    let inputURL: URL
    let outputURL: URL
    let presetName: String
    var state: ConversionState
    var progress: Double
    var errorMessage: String?

    var fileName: String {
        inputURL.lastPathComponent
    }

    var outputFileName: String {
        outputURL.lastPathComponent
    }
}
