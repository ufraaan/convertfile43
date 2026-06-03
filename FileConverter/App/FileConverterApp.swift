import SwiftUI

@main
struct convertfile43App: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var settings = AppSettings()
    @State private var orchestrator = ConversionOrchestrator(settings: AppSettings())
    init() {
        let settings = AppSettings()
        _settings = State(initialValue: settings)
        _orchestrator = State(initialValue: ConversionOrchestrator(settings: settings))
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent(settings: settings, orchestrator: orchestrator)
        } label: {
            MenuBarStatusLabel(orchestrator: orchestrator)
        }

        Settings {
            SettingsView()
                .environment(settings)
        }
    }
}
