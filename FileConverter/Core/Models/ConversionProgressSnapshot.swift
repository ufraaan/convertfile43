import Foundation

struct ConversionProgressSnapshot: Sendable, Equatable {
    let percent: Double
    let etaSeconds: TimeInterval?

    static let unknown = ConversionProgressSnapshot(percent: -1, etaSeconds: nil)
}

enum ETAFormatting {
    static func format(seconds: TimeInterval?) -> String? {
        guard let seconds, seconds.isFinite, seconds >= 1 else { return nil }
        let total = Int(seconds.rounded())
        if total < 60 { return "\(total)s left" }
        if total < 3600 {
            let m = total / 60
            let s = total % 60
            return s == 0 ? "\(m)m left" : "\(m)m \(s)s left"
        }
        let h = total / 3600
        let m = (total % 3600) / 60
        return m == 0 ? "\(h)h left" : "\(h)h \(m)m left"
    }
}
