import Foundation

enum FFmpegProgressParser {
    static func parseDuration(from stderr: String) -> TimeInterval? {
        guard let regex = try? NSRegularExpression(pattern: #"Duration:\s*(\d{1,2}):(\d{2}):(\d{2})\.(\d{2,3})"#) else {
            return nil
        }
        let range = NSRange(stderr.startIndex..., in: stderr)
        guard let match = regex.firstMatch(in: stderr, range: range),
              match.numberOfRanges >= 5,
              let hoursRange = Range(match.range(at: 1), in: stderr),
              let minutesRange = Range(match.range(at: 2), in: stderr),
              let secondsRange = Range(match.range(at: 3), in: stderr),
              let centiRange = Range(match.range(at: 4), in: stderr) else {
            return nil
        }

        let hours = Double(stderr[hoursRange]) ?? 0
        let minutes = Double(stderr[minutesRange]) ?? 0
        let seconds = Double(stderr[secondsRange]) ?? 0
        let frac = Double(stderr[centiRange]) ?? 0
        let fracDigits = stderr[centiRange].count
        let fracSeconds = frac / pow(10.0, Double(fracDigits))

        return hours * 3600 + minutes * 60 + seconds + fracSeconds
    }

    static func parseTime(from stderr: String) -> TimeInterval? {
        guard let regex = try? NSRegularExpression(pattern: #"time=\s*(\d{1,2}):(\d{2}):(\d{2})\.(\d{2,3})"#) else {
            return nil
        }
        let range = NSRange(stderr.startIndex..., in: stderr)
        var lastMatch: NSTextCheckingResult?
        regex.enumerateMatches(in: stderr, range: range) { match, _, _ in
            if let match { lastMatch = match }
        }

        guard let match = lastMatch,
              match.numberOfRanges >= 5,
              let hoursRange = Range(match.range(at: 1), in: stderr),
              let minutesRange = Range(match.range(at: 2), in: stderr),
              let secondsRange = Range(match.range(at: 3), in: stderr),
              let centiRange = Range(match.range(at: 4), in: stderr) else {
            return nil
        }

        let hours = Double(stderr[hoursRange]) ?? 0
        let minutes = Double(stderr[minutesRange]) ?? 0
        let seconds = Double(stderr[secondsRange]) ?? 0
        let frac = Double(stderr[centiRange]) ?? 0
        let fracDigits = stderr[centiRange].count
        let fracSeconds = frac / pow(10.0, Double(fracDigits))

        return hours * 3600 + minutes * 60 + seconds + fracSeconds
    }

    static func parseSpeed(from stderr: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: #"speed=\s*(\d+\.?\d*)x"#) else {
            return nil
        }
        let range = NSRange(stderr.startIndex..., in: stderr)
        var lastMatch: NSTextCheckingResult?
        regex.enumerateMatches(in: stderr, range: range) { match, _, _ in
            if let match { lastMatch = match }
        }

        guard let match = lastMatch,
              match.numberOfRanges >= 2,
              let speedRange = Range(match.range(at: 1), in: stderr) else {
            return nil
        }

        return Double(stderr[speedRange])
    }

    static func progress(from stderr: String) -> Double {
        snapshot(from: stderr)?.percent ?? -1
    }

    /// Wall-clock ETA: remaining media time divided by ffmpeg `speed=` (e.g. 2.5x realtime).
    static func estimatedSecondsRemaining(from stderr: String) -> TimeInterval? {
        guard let duration = parseDuration(from: stderr), duration >= 0.01,
              let time = parseTime(from: stderr),
              let speed = parseSpeed(from: stderr), speed > 0.01 else {
            return nil
        }
        let remaining = max(0, duration - time)
        return remaining / speed
    }

    static func snapshot(from stderr: String) -> ConversionProgressSnapshot? {
        guard let duration = parseDuration(from: stderr), duration >= 0.01,
              let time = parseTime(from: stderr) else {
            return nil
        }
        let percent = min(100, max(0, (time / duration) * 100))
        let eta = estimatedSecondsRemaining(from: stderr)
        return ConversionProgressSnapshot(percent: percent, etaSeconds: eta)
    }
}
