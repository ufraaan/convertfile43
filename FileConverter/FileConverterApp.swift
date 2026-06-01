import SwiftUI

@main
struct FileConverterApp: App {
    @State private var settings = AppSettings()
    @State private var conversionOrchestrator: ConversionOrchestrator?
    @State private var requestWatcher: FinderRequestWatcher?

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(settings)
                .environment(conversionOrchestrator ?? ConversionOrchestrator(settings: settings))
                .onAppear {
                    let orchestrator = ConversionOrchestrator(settings: settings)
                    conversionOrchestrator = orchestrator
                    requestWatcher = FinderRequestWatcher { request in
                        orchestrator.enqueue(request: request)
                    }
                }
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 800, height: 600)

        WindowGroup("Settings", id: "settings") {
            SettingsView()
                .environment(settings)
                .environment(conversionOrchestrator ?? ConversionOrchestrator(settings: settings))
        }

        WindowGroup("Help", id: "help") {
            HelpView()
        }
    }
}
