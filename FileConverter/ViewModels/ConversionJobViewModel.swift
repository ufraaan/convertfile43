import Foundation

@Observable
final class ConversionJobViewModel {
    var job: ConversionJob

    init(job: ConversionJob) {
        self.job = job
    }

    var progressFraction: Double {
        job.progress / 100.0
    }

    var statusIcon: String {
        switch job.state {
        case .queued: return "clock"
        case .running: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .cancelled: return "slash.circle"
        }
    }

    var statusColor: String {
        switch job.state {
        case .queued: return "gray"
        case .running: return "blue"
        case .completed: return "green"
        case .failed: return "red"
        case .cancelled: return "orange"
        }
    }
}
