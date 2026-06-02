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
        let manager = MenuBarManager()
        manager.setup(settings: settings, orchestrator: conversionOrchestrator)
        self.menuBarManager = manager
    }
}
