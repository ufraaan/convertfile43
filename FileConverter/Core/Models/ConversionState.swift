import Foundation

enum ConversionState: String, Codable, Sendable {
    case queued
    case running
    case completed
    case failed
    case cancelled
}
