import AppKit
import SwiftUI

@main
struct FileConverterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup("File Converter", id: "main") {
            MainView()
                .environment(appDelegate.settings)
                .environment(appDelegate.conversionOrchestrator)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 800, height: 600)

        WindowGroup("Settings", id: "settings") {
            SettingsView()
                .environment(appDelegate.settings)
                .environment(appDelegate.conversionOrchestrator)
        }

        WindowGroup("Help", id: "help") {
            HelpView()
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
