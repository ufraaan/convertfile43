import Foundation

struct FinderConversionRequest: Codable, Sendable {
    let files: [URL]
    let presetName: String
    let timestamp: Date
}
