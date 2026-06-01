import Foundation
import UserNotifications

enum NotificationService {
    static func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    static func sendCompletionNotification(job: ConversionJob) {
        let content = UNMutableNotificationContent()
        content.title = "Conversion Complete"
        content.body = "\(job.fileName) → \(job.outputFileName)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: job.id.uuidString,
            content: content,
            trigger: nil
        )

        Task {
            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    static func sendErrorNotification(job: ConversionJob) {
        let content = UNMutableNotificationContent()
        content.title = "Conversion Failed"
        content.body = "\(job.fileName): \(job.errorMessage ?? "Unknown error")"

        let request = UNNotificationRequest(
            identifier: job.id.uuidString,
            content: content,
            trigger: nil
        )

        Task {
            try? await UNUserNotificationCenter.current().add(request)
        }
    }
}
