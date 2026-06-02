import AppKit
import SwiftUI

@main
struct convertfile43App: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = AppSettings()
    private(set) lazy var conversionOrchestrator = ConversionOrchestrator(settings: settings)
    private var menuBarManager: MenuBarManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        LoggerService.sessionHeader()
        LoggerService.info("App launched", component: "AppDelegate")

        Task {
            await NotificationService.requestPermission()
        }

        validateBundledBinaries()

        let manager = MenuBarManager()
        manager.setup(settings: settings, orchestrator: conversionOrchestrator)
        self.menuBarManager = manager
    }

    private func validateBundledBinaries() {
        if let path = Bundle.main.path(forResource: "ffmpeg", ofType: nil) {
            LoggerService.info("Bundled binary found: ffmpeg at \(path)", component: "AppDelegate")
        } else {
            LoggerService.warning("Bundled binary missing: ffmpeg - conversions will fail",
                component: "AppDelegate")
        }
    }
}
