import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var isShuttingDown = false
    func applicationDidFinishLaunching(_ notification: Notification) {
        LoggerService.sessionHeader()
        LoggerService.info("App launched", component: "AppDelegate")
        Task { await NotificationService.requestPermission() }
        validateBundledBinaries()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !isShuttingDown else { return .terminateNow }
        isShuttingDown = true
        LoggerService.info("Quit requested — stopping conversion subprocesses", component: "AppDelegate")

        DispatchQueue.global(qos: .userInitiated).async {
            let orphansRemain = ConversionOrchestrator.shutdownForQuit()
            DispatchQueue.main.async {
                if orphansRemain {
                    QuitConfirmation.showOrphanFFmpegReminder()
                }
                sender.reply(toApplicationShouldTerminate: true)
            }
        }
        return .terminateLater
    }

    func applicationWillTerminate(_ notification: Notification) {
        LoggerService.info("App terminating — final subprocess cleanup", component: "AppDelegate")
        _ = ConversionOrchestrator.shutdownForQuit()
    }

    private func validateBundledBinaries() {
        for name in ["ffmpeg", "ffconv"] {
            if Bundle.main.path(forResource: name, ofType: nil) != nil {
                LoggerService.info("Bundled binary found: \(name)", component: "AppDelegate")
            } else {
                LoggerService.warning("Bundled binary missing: \(name)", component: "AppDelegate")
            }
        }
    }
}
